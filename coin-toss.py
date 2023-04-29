# Copyright 2022 Cartesi Pte. Ltd.
#
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use
# this file except in compliance with the License. You may obtain a copy of the
# License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

from os import environ
import logging
import requests
import json
import random
from enum import Enum

logging.basicConfig(level="INFO")
logger = logging.getLogger(__name__)

rollup_server = environ["ROLLUP_HTTP_SERVER_URL"]
logger.info(f"HTTP rollup_server url is {rollup_server}")

def hex2str(hex):
    """
    Decodes a hex string into a regular string
    """
    return bytes.fromhex(hex[2:]).decode("utf-8")

def str2hex(str):
    """
    Encodes a string as a hex string
    """
    return "0x" + str.encode("utf-8").hex()

def toss_coin(seed):
    random.seed(seed)
    return random.randint(0,1)


# {"address1": coin_side, "address2": coin_side, "seed": randomness}
def handle_advance(data):
    logger.info(f"Received advance request data {data}")

    payload_str = hex2str(data["payload"])
    status = "accept"
    try:
        payload_json = json.loads(payload_str)
        seed = payload_json.pop("seed")

        if len(payload_json) != 2:
            raise Exception(f"Payload should have the seed and the two players. Payload: {payload_json}")

        result = toss_coin(seed)

        winner = None
        for player, coin_choice in d.items():
            if result == coin_choice:
                winner = player
                break

        if winner is None:
            raise Exception(f"Invalid coin choices. {payload_json}")

        notice = payload_json
        notice["timestamp"] data["metadata"]["timestamp"]
        notice["winner"] = winner

        response = requests.post(rollup_server + "/notice", json={"payload": str2hex(json.dumps(notice))})
        logger.info(f"Received report status {response.status_code}")
    except Exception as e:
        status = "reject"
        response = requests.post(rollup_server + "/report", json={"payload": str2hex(str(e))})
        logger.info(f"Received report status {response.status_code} body {response.content}")

    return status

def handle_inspect(data):
    logger.info(f"Received inspect request data {data}")
    logger.info("Adding report")

    inspect_response = "Coin Toss DApp, send a seed and both players address to run a game."
    inspect_response_hex = str2hex(inspect_response)
    response = requests.post(rollup_server + "/report", json={"payload": inspect_response_hex})
    logger.info(f"Received report status {response.status_code}")
    return "accept"

handlers = {
    "advance_state": handle_advance,
    "inspect_state": handle_inspect,
}

finish = {"status": "accept"}
rollup_address = None

while True:
    logger.info("Sending finish")
    response = requests.post(rollup_server + "/finish", json=finish)
    logger.info(f"Received finish status {response.status_code}")
    if response.status_code == 202:
        logger.info("No pending rollup request, trying again")
    else:
        rollup_request = response.json()
        data = rollup_request["data"]
        if "metadata" in data:
            metadata = data["metadata"]
            if metadata["epoch_index"] == 0 and metadata["input_index"] == 0:
                rollup_address = metadata["msg_sender"]
                logger.info(f"Captured rollup address: {rollup_address}")
                continue
        handler = handlers[rollup_request["request_type"]]
        finish["status"] = handler(rollup_request["data"])
