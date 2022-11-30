// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

// Common Errors
error ZERO_AMOUNT();
error ZERO_ADDRESS();
error INPUT_ARRAY_MISMATCH();

// Oracle Errors
error TOO_LONG_DELAY(uint256 delayTime);
error NO_MAX_DELAY(address token);
error PRICE_OUTDATED(address token);
error NO_SYM_MAPPING(address token);

error OUT_OF_DEVIATION_CAP(uint256 deviation);
error EXCEED_SOURCE_LEN(uint256 length);
error NO_PRIMARY_SOURCE(address token);
error NO_VALID_SOURCE(address token);
error EXCEED_DEVIATION();

error TOO_LOW_MEAN(uint256 mean);
error NO_MEAN(address token);
error NO_STABLEPOOL(address token);

error PRICE_FAILED(address token);
error LIQ_THRESHOLD_TOO_HIGH(uint256 threshold);

error ORACLE_NOT_SUPPORT(address token);
error ORACLE_NOT_SUPPORT_LP(address lp);
error ORACLE_NOT_SUPPORT_WTOKEN(address wToken);
error ERC1155_NOT_WHITELISTED(address collToken);
error NO_ORACLE_ROUTE(address token);

// Spell
error NOT_BANK(address caller);
error REFUND_ETH_FAILED(uint256 balance);
error NOT_FROM_WETH(address from);
error LP_NOT_WHITELISTED(address lp);
error COL_NOT_WHITELISTED(uint256 poolId, address colToken);
error NOT_EXIST_STRATEGY(address spell, uint poolId);
error EXCEED_MAX_LIMIT(uint poolId);

// Ichi Spell
error INCORRECT_LP(address lpToken);
error INCORRECT_PID(uint256 pid);
error INCORRECT_COLTOKEN(address colToken);
error INCORRECT_UNDERLYING(address uToken);
error NOT_FROM_UNIV3(address sender);

// SafeBox
error BORROW_FAILED(uint256 amount);
error REPAY_FAILED(uint256 amount);
error LEND_FAILED(uint256 amount);
error REDEEM_FAILED(uint256 amount);

// Wrapper
error INVALID_TOKEN_ID(uint256 tokenId);
error BAD_PID(uint256 pid);
error BAD_REWARD_PER_SHARE(uint256 rewardPerShare);

// Bank
error FEE_TOO_HIGH(uint256 feeBps);
error NOT_UNDER_EXECUTION();
error BANK_NOT_LISTED(address token);
error BANK_ALREADY_LISTED();
error BANK_LIMIT();
error CTOKEN_ALREADY_ADDED();
error NOT_EOA(address from);
error LOCKED();
error NOT_FROM_SPELL(address from);
error NOT_FROM_OWNER(uint256 positionId, address sender);
error NOT_IN_EXEC();
error ANOTHER_COL_EXIST(address collToken);
error NOT_LIQUIDATABLE(uint256 positionId);
error BAD_POSITION(uint256 posId);
error BAD_COLLATERAL(uint256 positionId);
error INSUFFICIENT_COLLATERAL();
error SPELL_NOT_WHITELISTED(address spell);
error TOKEN_NOT_WHITELISTED(address token);
error REPAY_EXCEEDS_DEBT(uint256 repay, uint256 debt);
error LEND_NOT_ALLOWED();
error BORROW_NOT_ALLOWED();
error REPAY_NOT_ALLOWED();

// Config
error INVALID_FEE_DISTRIBUTION();
error NO_TREASURY_SET();