// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import '@openzeppelin/contracts/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '../interfaces/IERC721Mintable.sol';
import '../libraries/TransferHelper.sol';
import '../interfaces/IWETH.sol';

contract RewardClaim is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event NewRewardToken(IERC20 oldRewardToken, IERC20 newRewardToken);
    event NewVault(address oldVault, address newVault);
    event NewDispatcher(address oldDispatcher, address newDispatcher);
    event NewVerifier(address oldVerifier, address newVerifier);
    event NewCaller(address oldCaller, address newCaller);
    event NewDispatchReward(address from, address to, uint amount);
    event NewErc20ClaimAmount(uint loop, address user, address token, uint amount);
    event NewErc721ClaimAmount(uint loop, address user, address token, uint tokenId, bool claimed);
    event NewErc1155ClaimAmount(uint loop, address user, address token, uint tokenId, uint amount);
    event ClaimFlag(uint loop, bool flag);

    address public vault;
    address public verifier;
    mapping(uint => bool) public claimDisabled;
    //loop->user->token => amount
    mapping(uint => mapping(address => mapping(address => uint))) public erc20Claimed;
    //loop->user->token->tokenId=>claimed
    mapping(uint => mapping(address => mapping(address => mapping(uint => bool)))) public erc721Claimed;
    //loop->user->token->tokenId=>amount
    mapping(uint => mapping(address => mapping(address => mapping(uint => uint)))) public erc1155Claimed;
    IWETH immutable public WETH;
    mapping(address => bool) public mintContract;

    enum TokenType{
        ERC20,
        ERC721,
        ERC1155
    }

    function setMintContract(address _contract) external onlyOwner {
        mintContract[_contract] = true;
    }

    function delMintContract(address _contract) external onlyOwner {
        delete mintContract[_contract];
    }

    function setVault(address _vault) external onlyOwner {
        emit NewVault(vault, _vault);
        vault = _vault;
    }

    function setVerifier(address _verifier) external onlyOwner {
        emit NewVerifier(verifier, _verifier);
        verifier = _verifier;
    }

    function claimDisable(uint _loop) external onlyOwner {
        claimDisabled[_loop] = true;
        emit ClaimFlag(_loop, true);
    }

    function claimEnable(uint _loop) external onlyOwner {
        delete claimDisabled[_loop];
        emit ClaimFlag(_loop, false);
    }

    function setUserErc20Claimed(uint _loop, address _user, address _token, uint _amount) external onlyOwner {
        erc20Claimed[_loop][_user][_token] = _amount;
        emit NewErc20ClaimAmount(_loop, _user, _token, _amount);
    }

    function setUserErc721Claimed(uint _loop, address _user, address _token, uint _tokenId, bool _claimed) external onlyOwner {
        if (_claimed) {
            erc721Claimed[_loop][_user][_token][_tokenId] = true; 
        } else {
            delete erc721Claimed[_loop][_user][_token][_tokenId];
        }
        emit NewErc721ClaimAmount(_loop, _user, _token, _tokenId, _claimed);
    }

    function setUserErc1155Claimed(uint _loop, address _user, address _token, uint _tokenId, uint _amount) external onlyOwner {
        erc1155Claimed[_loop][_user][_token][_tokenId] = _amount;
        emit NewErc1155ClaimAmount(_loop, _user, _token, _tokenId, _amount);
    }

    constructor(address _vault, address _verifier, address _WETH) {
        emit NewVault(vault, _vault);
        vault = _vault;
        emit NewVerifier(verifier, _verifier);
        verifier = _verifier;
        WETH = IWETH(_WETH);
    }

    function getEncodePacked(uint _loop, address _contract, address _token, uint _type, address _user, uint _tokenId, uint _amount, uint _timestamp) public pure returns (bytes memory) {
        return abi.encodePacked(_loop, _contract, _token, _type, _user, _tokenId, _amount, _timestamp);
    }

    function getHash(uint _loop, address _contract, address _token, uint _type, address _user, uint _tokenId, uint _amount, uint _timestamp) public pure returns (bytes32) {
        return keccak256(getEncodePacked(_loop, _contract, _token, _type, _user, _tokenId, _amount, _timestamp));
    }

    function getHashToSign(uint _loop, address _contract, address _token, uint _type, address _user, uint _tokenId, uint _amount, uint _timestamp) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", getHash(_loop, _contract, _token, _type, _user, _tokenId, _amount, _timestamp)));
    }

    function verify(uint _loop, address _contract, address _token, uint _type, address _user, uint _tokenId, uint _amount, uint _timestamp, uint8 _v, bytes32 _r, bytes32 _s) public view returns (bool) {
        return ecrecover(getHashToSign(_loop, _contract, _token, _type, _user, _tokenId, _amount, _timestamp), _v, _r, _s) == verifier;
    }

    function claimErc20(uint _loop, address _token, address _user, uint _amount) internal {
        _amount = _amount.sub(erc20Claimed[_loop][_user][_token]);
        erc20Claimed[_loop][_user][_token] = erc20Claimed[_loop][_user][_token].add(_amount);
        if (_amount > 0) {
            if (_token == address(WETH)) {
                SafeERC20.safeTransferFrom(IERC20(_token), vault, address(this), _amount);
                WETH.withdraw(_amount);
                TransferHelper.safeTransferETH(_user, _amount);
            } else {
                SafeERC20.safeTransferFrom(IERC20(_token), vault, _user, _amount);
            }
        }
    }

    function claimErc721(uint _loop, address _token, address _user, uint _tokenId) internal {
        if (!erc721Claimed[_loop][_user][_token][_tokenId]) {
            erc721Claimed[_loop][_user][_token][_tokenId] = true;
            if (!mintContract[_token]) {
                IERC721(_token).safeTransferFrom(vault, _user, _tokenId);
            } else {
                IERC721Mintable(_token).mint(_user, _tokenId);
            }
        }
    }

    function claimErc1155(uint _loop, address _token, address _user, uint _tokenId, uint _amount) internal {
        _amount = _amount.sub(erc1155Claimed[_loop][_user][_token][_tokenId]);
        erc1155Claimed[_loop][_user][_token][_tokenId] = erc1155Claimed[_loop][_user][_token][_tokenId].add(_amount);
        if (_amount > 0) {
            IERC1155(_token).safeTransferFrom(vault, _user, _tokenId, _amount, new bytes(0));
        }
    }

    function claim(uint _loop, address _contract, address _token, uint _type, address _user, uint _tokenId, uint _amount, uint _timestamp, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(!claimDisabled[_loop], "loop already finish");
        require(_contract == address(this), "illegal target");
        require(_timestamp > block.timestamp, "signature expired");
        require(verify(_loop, _contract, _token, _type, _user, _tokenId, _amount, _timestamp, _v, _r, _s), "signature illegal");
        if (TokenType(_type) ==TokenType.ERC20) {
            claimErc20(_loop, _token, _user, _amount);
        } else if (TokenType(_type) == TokenType.ERC721) {
            claimErc721(_loop, _token, _user, _tokenId);
        } else if (TokenType(_type) == TokenType.ERC1155) {
            claimErc1155(_loop, _token, _user, _tokenId, _amount);
        } else {
            revert("illegal type");
        }
    }

    function transferContractOwnership(address _contract, address _to) external onlyOwner {
        Ownable(_contract).transferOwnership(_to);
    }

    receive () external payable {}
}