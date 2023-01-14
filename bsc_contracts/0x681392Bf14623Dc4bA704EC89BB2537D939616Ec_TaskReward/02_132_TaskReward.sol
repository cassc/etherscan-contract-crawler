// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IERC721Mintable.sol';
import '../interfaces/IERC1155Mintable.sol';
import '../libraries/TransferHelper.sol';
import '../interfaces/IWETH.sol';
import '../token/BabyVault.sol';
import '../core/SafeOwnable.sol';

contract TaskReward is SafeOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum VAULT_TYPE {
        NOT_VAULT,
        FROM_ALL,
        FROM_BALANCE,
        FROM_TOKEN,
        NOT_CHANGE
    }

    event TokenVault(address token, address oldVault, address newVault);
    event VaultType(address vault, VAULT_TYPE oldType, VAULT_TYPE newType);
    event MintContractChanged(address changedContract, bool flag);
    event TaskChanged(uint task, bool disabled);
    event NewVerifier(address oldVerifier, address newVerifier);
    event NewErc20ClaimAmount(uint task, address user, IERC20 token, uint totalAmount, uint amount);
    event NewErc721ClaimAmount(uint task, address user, IERC721 token, uint tokenId, bool claimed);
    event NewErc1155ClaimAmount(uint task, address user, IERC1155 token, uint tokenId, uint totalAmount, uint amount);

    address constant public ALL_TOKEN_FLAG = 0x000000000000000000000000000000005497649F;
    IWETH immutable public WETH;

    //token => vault: from which vault to fetch this token
    mapping(address => address) public vaults;
    //vault => flag: weather fech from a BabyVaultContract or just safeTransferFrom
    mapping(address => VAULT_TYPE) public vaultType;
    //token => flag: if is NFT, use mint or transferFrom
    mapping(address => bool) public isMintContract;
    //signature verifier
    address public verifier;
    //if disabled, the unclaimed token for this task, can not claim anymore
    mapping(uint => bool) public taskDisabled;
    //task->user->token => amount already claimed erc20
    mapping(uint => mapping(address => mapping(IERC20 => uint))) public erc20Claimed;
    //loop->user->token->tokenId=>claimed already claimed erc721
    mapping(uint => mapping(address => mapping(IERC721 => mapping(uint => bool)))) public erc721Claimed;
    //task->user->token->tokenId=>amount already claimed erc1155
    mapping(uint => mapping(address => mapping(IERC1155 => mapping(uint => uint)))) public erc1155Claimed;
    //token type
    enum TokenType{
        ERC20,
        ERC721,
        ERC1155
    }
    function setVault(address _token, address _vault, VAULT_TYPE _vaultType) public onlyOwner {
        emit TokenVault(_token, vaults[_token], _vault);
        vaults[_token] = _vault;
        if (_vaultType != VAULT_TYPE.NOT_CHANGE) {
            emit VaultType(_vault, vaultType[_vault], _vaultType);
            vaultType[_vault] = _vaultType;
        }
    }

    function setVaultType(address _vault, VAULT_TYPE _vaultType) external onlyOwner {
        require(_vaultType != VAULT_TYPE.NOT_CHANGE, "illegal vaultType");
        emit VaultType(_vault, vaultType[_vault], _vaultType);
        vaultType[_vault] = _vaultType;
    }

    function setMintContract(address _contract, bool _flag) external onlyOwner {
        isMintContract[_contract] = _flag;
        emit MintContractChanged(_contract, _flag);
    }

    function setVerifier(address _verifier) public onlyOwner {
        emit NewVerifier(verifier, _verifier);
        verifier = _verifier;
    }

    function setTask(uint _task, bool _disable) external onlyOwner {
        taskDisabled[_task] = _disable; 
        emit TaskChanged(_task, _disable);
    }

    function setUserErc20Claimed(uint _task, address _user, IERC20 _token, uint _amount) external onlyOwner {
        erc20Claimed[_task][_user][_token] = _amount;
        emit NewErc20ClaimAmount(_task, _user, _token, _amount, _amount);
    }

    function setUserErc721Claimed(uint _task, address _user, IERC721 _token, uint _tokenId, bool _claimed) external onlyOwner {
        erc721Claimed[_task][_user][_token][_tokenId] = _claimed;
        emit NewErc721ClaimAmount(_task, _user, _token, _tokenId, _claimed);
    }

    function setUserErc1155Claimed(uint _task, address _user, IERC1155 _token, uint _tokenId, uint _amount) external onlyOwner {
        erc1155Claimed[_task][_user][_token][_tokenId] = _amount;
        emit NewErc1155ClaimAmount(_task, _user, _token, _tokenId, _amount, _amount);
    }

    constructor(address _defaultVault, address _verifier, address _WETH) {
        setVault(ALL_TOKEN_FLAG, _defaultVault, VAULT_TYPE.NOT_VAULT);
        setVerifier(_verifier);
        WETH = IWETH(_WETH);
    }

    struct ClaimParams {
        uint task;              //task id
        TokenType tokenType;    //token type
        address token;          //token contract
        address recipient;      //receiver address
        uint tokenId;           //for NFT is tokenId, for ERC20 is always 0
        uint amount;            //for ERC1155 and ERC20 is amount, for ERC721 is always 0
    }

    function fetch(address _vault, IERC20 _token, address _to, uint _amount) internal returns(uint) {
        VAULT_TYPE currentType = vaultType[_vault];
        if (currentType == VAULT_TYPE.NOT_VAULT) {
            _token.safeTransferFrom(_vault, _to, _amount);
            return _amount;
        } else if (currentType == VAULT_TYPE.FROM_ALL) {
            return BabyVault(_vault).mint(_to, _amount);
        } else if (currentType == VAULT_TYPE.FROM_BALANCE) {
            return BabyVault(_vault).mintOnlyFromBalance(_to, _amount);
        } else if (currentType == VAULT_TYPE.FROM_TOKEN) {
            return BabyVault(_vault).mintOnlyFromToken(_to, _amount);
        } 
        return 0;
    }

    function erc20Claim(ClaimParams memory _info) internal {
        require(_info.tokenId == 0, "illegal tokenId");
        uint receiveAmount = _info.amount.sub(erc20Claimed[_info.task][_info.recipient][IERC20(_info.token)]);
        if (receiveAmount > 0) {
            address vault = vaults[_info.token] != address(0) ? vaults[_info.token] : vaults[ALL_TOKEN_FLAG];
            if (address(_info.token) == address(WETH)) {
                require(fetch(vault, IERC20(_info.token), address(this), receiveAmount) == receiveAmount, "out of token");
                WETH.withdraw(receiveAmount);
                TransferHelper.safeTransferETH(_info.recipient, receiveAmount);
            } else {
                require(fetch(vault, IERC20(_info.token), _info.recipient, receiveAmount) == receiveAmount, "out of token");
            }
            erc20Claimed[_info.task][_info.recipient][IERC20(_info.token)] = _info.amount;
            emit NewErc20ClaimAmount(_info.task, _info.recipient, IERC20(_info.token), _info.amount, receiveAmount);
        }
    }

    function erc721Claim(ClaimParams memory _info) internal {
        require(_info.amount == 0, "illegal amount");
        if (!erc721Claimed[_info.task][_info.recipient][IERC721(_info.token)][_info.tokenId]) {
            address vault = vaults[_info.token] != address(0) ? vaults[_info.token] : vaults[ALL_TOKEN_FLAG];
            if (!isMintContract[_info.token]) {
                IERC721(_info.token).safeTransferFrom(vault, _info.recipient, _info.tokenId);
            } else {
                IERC721Mintable(_info.token).mint(_info.recipient, _info.tokenId);
            }
            erc721Claimed[_info.task][_info.recipient][IERC721(_info.token)][_info.tokenId] = true;
            emit NewErc721ClaimAmount(_info.task, _info.recipient, IERC721(_info.token), _info.tokenId, true);
        }
    }

    function erc1155Claim(ClaimParams memory _info) internal {
        uint receiveAmount = _info.amount.sub(erc1155Claimed[_info.task][_info.recipient][IERC1155(_info.token)][_info.tokenId]);
        if (receiveAmount > 0) {
            address vault = vaults[_info.token] != address(0) ? vaults[_info.token] : vaults[ALL_TOKEN_FLAG];
            if (!isMintContract[_info.token]) {
                IERC1155(_info.token).safeTransferFrom(vault, _info.recipient, _info.tokenId, receiveAmount, new bytes(0));
            } else {
                IERC1155Mintable(_info.token).mint(_info.recipient, _info.tokenId, receiveAmount);
            }
            erc1155Claimed[_info.task][_info.recipient][IERC1155(_info.token)][_info.tokenId] = _info.amount;
            emit NewErc1155ClaimAmount(_info.task, _info.recipient, IERC1155(_info.token), _info.tokenId, _info.amount, receiveAmount);
        }
    }

    function claim(ClaimParams memory _info, uint _timestamp, uint8 _v, bytes32 _r, bytes32 _s) external {
        //check params
        require(!taskDisabled[_info.task], "task already finish");
        require(_timestamp > block.timestamp, "signature expired");
        //check signature
        bytes memory data = abi.encodePacked(_info.task, address(this), _info.token, _info.tokenType, _info.recipient, _info.tokenId, _info.amount, _timestamp);
        bytes32 hash = keccak256(data);
        address recover = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _r, _s);
        require(recover != address(0) && recover == verifier, "verify failed");
        if (_info.tokenType ==TokenType.ERC20) {
            erc20Claim(_info);
        } else if (_info.tokenType == TokenType.ERC721) {
            erc721Claim(_info);
        } else if (_info.tokenType == TokenType.ERC1155) {
            erc1155Claim(_info);
        } else {
            revert("illegal type");
        }
    }

    function execute(address _to, bytes memory _data) external onlyOwner {
        (bool success, ) = _to.call(_data);
        require(success, "failed");
    }

    receive () external payable {}
}