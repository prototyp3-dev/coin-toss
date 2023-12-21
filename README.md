**milestone: splitting a payload into multiple vouchers**
works:
- split LLM response into multiple vouchers
- automated testing for multiple vouchers
(details below)
Problems I'm currently working on:
- even though 200+ random :alpha: + space character strings work, the llama2.c inference doesn't post a notice.
Todo: 
- run on test net
- write docs
- simple ui

the log of the dbf2a0e9d4c3814737987f9cfb05ee3948a42e47
https://github.com/kirilligum/coin-toss/raw/ic08/runs_history/2023-12-21T19:01:39+00:00/2023-12-21T19:01:39+00:00__ic08/commit.log
shows:
- submit an instruction to an LLM inside cartesi
- notice shows responses
- we see a list of vouchers, where each voucher is 512 characters of the response
- vouchers get executed
- we see vouchers on-chain
- we give human feedback on the best response on-chain
