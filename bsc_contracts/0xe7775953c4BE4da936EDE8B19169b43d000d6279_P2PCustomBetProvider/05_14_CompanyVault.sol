// SPDX-License-Identifier: MIT

// solhint-disable-next-line
pragma solidity 0.8.2;

import "../security/Security.sol";
import "../utils/IERC20.sol";

abstract contract CompanyVault is Security {
    SecurityDTOs.ChangeAlterToken public changeAlterToken;
    IERC20 internal _IERC20token;
    IERC20 internal _AlternativeIERC20token;
    mapping(address => uint) private feeBalance;
    bool private _alternativeTokenEnabled;
    uint private _timestampExpirationDelay;

    event ChangeAlterToken(address indexed newAlterToken);
    event ChangeTimestampDelay(uint timestampExpirationDelay);

    constructor (address mainToken) {
        _IERC20token = IERC20(mainToken);
        _timestampExpirationDelay = 2 * 60 * 60;
    }

    // Set expiration delay
    function setTimestampExpirationDelay(uint timestampExpirationDelay) external onlyOwner {
        _timestampExpirationDelay = timestampExpirationDelay;
        emit ChangeTimestampDelay(timestampExpirationDelay);
    }

    // Change alter token start voting
    function changeAlternativeTokenStart(address alternativeToken) external onlyOwner {
        require(address(getMainIERC20Token()) != alternativeToken, "CompanyVault: main token and alter token can't be the same");
        uint votingCode = startVoting("CHANGE_ALTER_TOKEN");
        changeAlterToken = SecurityDTOs.ChangeAlterToken(
            alternativeToken,
            block.timestamp,
            votingCode
        );
    }

    // Acquire alter token start voting
    function acquireNewAlternativeToken() external onlyOwner {
        pass(changeAlterToken.votingCode);
        _AlternativeIERC20token = IERC20(changeAlterToken.newAlterToken);
        emit ChangeAlterToken(changeAlterToken.newAlterToken);
    }

    // Get expiration delay to refund
    function getTimestampExpirationDelay() public view returns (uint) {
        return _timestampExpirationDelay;
    }

    // Enable/disable alternative token usage
    function enableAlternativeToken(bool enable) external onlyOwner {
        _alternativeTokenEnabled = enable;
    }

    // Status of alternative token
    function isAlternativeTokenEnabled() public view returns (bool) {
        return _alternativeTokenEnabled;
    }

    // Get main IERC20 interface
    function getMainIERC20Token() public view returns (IERC20) {
        return _IERC20token;
    }

    // Get alternative IERC20 interface
    function getAlternativeIERC20Token() public view returns (IERC20) {
        return _AlternativeIERC20token;
    }

    // Get fee company balance
    function getCompanyFeeBalance(address token) public view returns (uint) {
        return feeBalance[token];
    }

    // Increase main or alter token fee. Calls only from take prize.
    function increaseFee(uint amount, address token) internal {
        feeBalance[token] += amount;
    }

    // Decrease main or alter token fee. Calls only from take fee.
    function decreaseFee(uint amount, address token) internal {
        feeBalance[token] -= amount;
    }
}