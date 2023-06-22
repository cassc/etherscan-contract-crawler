/**
 *Submitted for verification at Etherscan.io on 2023-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);
}

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Ownable {
    address private _owner;
    mapping(address => bool) public contractAccess;

    event OwnershipTransferred(address _previousOwner, address _newOwner);

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        address previousOwner = _owner;
        _owner = _newOwner;

        _afterTransferOwnership(previousOwner, _newOwner);

        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function _afterTransferOwnership(
        address _previousOwner,
        address _newOwner
    ) internal virtual {}
}

contract JBMigration is Ownable {
    using SafeMath for uint256;

    IERC20 private V1Token;
    IERC20 private V2Token;
    uint256 private exchangeRate;
    bool private canClaim = false;
    mapping(address => uint256) private depositedV1Tokens;
    mapping(address => uint256) private claimedV2Tokens;

    event DepositV1Tokens(address _user, uint256 _v1TokenAmount);
    event ClaimV2Tokens(address _user, uint256 _tokenAmount);

    event WithdrawTokens(
        address _user,
        address _tokenAddress,
        uint256 _tokenAmount
    );

    constructor(
        address _v1TokenAddress,
        address _v2TokenAddress,
        uint256 _exchangeRate
    ) {
        V1Token = IERC20(_v1TokenAddress);
        V2Token = IERC20(_v2TokenAddress);
        exchangeRate = _exchangeRate;
    }

    function depositV1Tokens(uint256 _v1TokenAmount) external {
        address user = msg.sender;
        depositedV1Tokens[user] = depositedV1Tokens[user].add(_v1TokenAmount);
        V1Token.transferFrom(user, address(this), _v1TokenAmount);

        emit DepositV1Tokens(user, _v1TokenAmount);
    }

    function claimV2Tokens() external {
        require(canClaim, "Claim is paused");
        address user = msg.sender;

        uint256 totalDepositedV1Tokens = depositedV1Tokens[user];
        uint256 totalClaimedV2Tokens = claimedV2Tokens[user];

        uint256 claimableV2Tokens = totalDepositedV1Tokens
            .mul(exchangeRate)
            .sub(totalClaimedV2Tokens);

        require(claimableV2Tokens > 0, "No claimable tokens");

        claimedV2Tokens[user] = claimedV2Tokens[user].add(claimableV2Tokens);

        V2Token.transfer(user, claimableV2Tokens);

        emit ClaimV2Tokens(user, claimableV2Tokens);
    }

    function withdrawV1Tokens() external onlyOwner {
        address user = msg.sender;
        uint256 v1TokenContractBalance = getV1TokenContractBalance();
        V1Token.transfer(user, v1TokenContractBalance);

        emit WithdrawTokens(user, address(V1Token), v1TokenContractBalance);
    }

    function withdrawV2Tokens() external onlyOwner {
        address user = msg.sender;
        uint256 v2TokenContractBalance = getV2TokenContractBalance();
        V2Token.transfer(user, v2TokenContractBalance);

        emit WithdrawTokens(user, address(V2Token), v2TokenContractBalance);
    }

    function withdrawAnyTokens(address _tokenAddress) external onlyOwner {
        address user = msg.sender;
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenContractBalance = token.balanceOf(address(this));
        token.transfer(user, tokenContractBalance);

        emit WithdrawTokens(user, _tokenAddress, tokenContractBalance);
    }

    function setClaimStatus(bool _onoff) external onlyOwner {
        require(canClaim != _onoff);
        canClaim = _onoff;
    }

    function setV2TokenAddress(address _v2TokenAddress) external onlyOwner {
        require(address(V2Token) != _v2TokenAddress);
        V2Token = IERC20(_v2TokenAddress);
    }

    function getV1TokenContractBalance() public view returns (uint256) {
        return V1Token.balanceOf(address(this));
    }

    function getV2TokenContractBalance() public view returns (uint256) {
        return V2Token.balanceOf(address(this));
    }

    function getUserData(
        address _user
    ) external view returns (uint256, uint256, uint256, bool) {
        uint256 totalDepositedV1Tokens = depositedV1Tokens[_user];
        uint256 totalClaimedV2Tokens = claimedV2Tokens[_user];

        uint256 claimableV2Tokens = totalDepositedV1Tokens
            .mul(exchangeRate)
            .sub(totalClaimedV2Tokens);

        return (
            totalDepositedV1Tokens,
            totalClaimedV2Tokens,
            claimableV2Tokens,
            canClaim
        );
    }
}