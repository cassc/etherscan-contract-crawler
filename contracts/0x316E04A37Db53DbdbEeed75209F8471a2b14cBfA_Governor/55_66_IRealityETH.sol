// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.10;

import './IBalanceHolder.sol';

interface IRealityETH is IBalanceHolder {
     event LogAnswerReveal (bytes32 indexed question_id, address indexed user, bytes32 indexed answer_hash, bytes32 answer, uint256 nonce, uint256 bond);
     event LogCancelArbitration (bytes32 indexed question_id);
     event LogClaim (bytes32 indexed question_id, address indexed user, uint256 amount);
     event LogFinalize (bytes32 indexed question_id, bytes32 indexed answer);
     event LogFundAnswerBounty (bytes32 indexed question_id, uint256 bounty_added, uint256 bounty, address indexed user);
     event LogMinimumBond (bytes32 indexed question_id, uint256 min_bond);
     event LogNewAnswer (bytes32 answer, bytes32 indexed question_id, bytes32 history_hash, address indexed user, uint256 bond, uint256 ts, bool is_commitment);
     event LogNewQuestion (bytes32 indexed question_id, address indexed user, uint256 template_id, string question, bytes32 indexed content_hash, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 created);
     event LogNewTemplate (uint256 indexed template_id, address indexed user, string question_text);
     event LogNotifyOfArbitrationRequest (bytes32 indexed question_id, address indexed user);
     event LogReopenQuestion (bytes32 indexed question_id, bytes32 indexed reopened_question_id);
     event LogSetQuestionFee (address arbitrator, uint256 amount);

     function assignWinnerAndSubmitAnswerByArbitrator (bytes32 question_id, bytes32 answer, address payee_if_wrong, bytes32 last_history_hash, bytes32 last_answer_or_commitment_id, address last_answerer) external;
     function cancelArbitration (bytes32 question_id) external;
     function claimMultipleAndWithdrawBalance (bytes32[] calldata question_ids, uint256[] calldata lengths, bytes32[] calldata hist_hashes, address[] calldata addrs, uint256[] calldata bonds, bytes32[] calldata answers) external;
     function claimWinnings (bytes32 question_id, bytes32[] calldata history_hashes, address[] calldata addrs, uint256[] calldata bonds, bytes32[] calldata answers) external;
     function createTemplate (string calldata content) external returns (uint256);
     function notifyOfArbitrationRequest (bytes32 question_id, address requester, uint256 max_previous) external;
     function setQuestionFee (uint256 fee) external;
     function submitAnswerByArbitrator (bytes32 question_id, bytes32 answer, address answerer) external;
     function submitAnswerReveal (bytes32 question_id, bytes32 answer, uint256 nonce, uint256 bond) external;
     function askQuestion (uint256 template_id, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) external payable returns (bytes32);
     function askQuestionWithMinBond (uint256 template_id, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 min_bond) external payable returns (bytes32);
     function createTemplateAndAskQuestion (string calldata content, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) external payable returns (bytes32);
     function fundAnswerBounty (bytes32 question_id) external payable;
     function reopenQuestion (uint256 template_id, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 min_bond, bytes32 reopens_question_id) external payable returns (bytes32);
     function submitAnswer (bytes32 question_id, bytes32 answer, uint256 max_previous) external payable;
     function submitAnswerCommitment (bytes32 question_id, bytes32 answer_hash, uint256 max_previous, address _answerer) external payable;
     function submitAnswerFor (bytes32 question_id, bytes32 answer, uint256 max_previous, address answerer) external payable;
     function arbitrator_question_fees (address) external view returns (uint256);
     function commitments (bytes32) external view returns (uint32 reveal_ts, bool is_revealed, bytes32 revealed_answer);
     function getArbitrator (bytes32 question_id) external view returns (address);
     function getBestAnswer (bytes32 question_id) external view returns (bytes32);
     function getBond (bytes32 question_id) external view returns (uint256);
     function getBounty (bytes32 question_id) external view returns (uint256);
     function getContentHash (bytes32 question_id) external view returns (bytes32);
     function getFinalAnswer (bytes32 question_id) external view returns (bytes32);
     function getFinalAnswerIfMatches (bytes32 question_id, bytes32 content_hash, address arbitrator, uint32 min_timeout, uint256 min_bond) external view returns (bytes32);
     function getFinalizeTS (bytes32 question_id) external view returns (uint32);
     function getHistoryHash (bytes32 question_id) external view returns (bytes32);
     function getMinBond (bytes32 question_id) external view returns (uint256);
     function getOpeningTS (bytes32 question_id) external view returns (uint32);
     function getTimeout (bytes32 question_id) external view returns (uint32);
     function isFinalized (bytes32 question_id) external view returns (bool);
     function isPendingArbitration (bytes32 question_id) external view returns (bool);
     function isSettledTooSoon (bytes32 question_id) external view returns (bool);
     function question_claims (bytes32) external view returns (address payee, uint256 last_bond, uint256 queued_funds);
     function questions (bytes32) external view returns (bytes32 content_hash, address arbitrator, uint32 opening_ts, uint32 timeout, uint32 finalize_ts, bool is_pending_arbitration, uint256 bounty, bytes32 best_answer, bytes32 history_hash, uint256 bond, uint256 min_bond);
     function reopened_questions (bytes32) external view returns (bytes32);
     function reopener_questions (bytes32) external view returns (bool);
     function resultFor (bytes32 question_id) external view returns (bytes32);
     function resultForOnceSettled (bytes32 question_id) external view returns (bytes32);
     function template_hashes (uint256) external view returns (bytes32);
     function templates (uint256) external view returns (uint256);
}