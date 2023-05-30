// contracts/TeaVaultV2.sol
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./IFilterMapper.sol";

error InvalidOwnerAddress();
error CallerIsNotInvestor();
error CallerIsNotManager();
error FilterMapperNotAssigned();
error ContractNotInWhitelist();
error InvalidFilter();
error InvalidFilterReturnValue();
error InvalidContractAddress();
error InconsistentParamsLengths();
error IncorrectValue();
error InvalidRecipientAddress();

/// @title A generalized managed investor vault
/// @notice Fund manager is only allowed to call functions whitelisted in the filters
/// @author Teahouse Finance
contract TeaVaultV2 is ReentrancyGuard, Ownable, IERC721Receiver, ERC1155Receiver {

    struct Config {
        IFilterMapper filterMapper;
        address investor;
        address manager;
        bool allowManagerSignature;
    }

    Config public config;

    event FilterMapperChanged(address indexed sender, address newFilterMapper);
    event ManagerChanged(address indexed sender, address newManager);
    event InvestorChanged(address indexed sender, address newInvestor);
    event AllowManagerSignatureChanged(address indexed sender, bool newStatus);
    event TokenDeposited(address indexed sender, address indexed token, uint256 amount);
    event TokenWithdrawed(address indexed sender, address indexed recipient, address indexed token, uint256 amount);
    event Token721Deposited(address indexed sender, address indexed token, uint256 tokenId);
    event Token721Withdrawed(address indexed sender, address indexed recipient, address indexed token, uint256 tokenId);
    event Token1155Deposited(address indexed sender, address indexed token, uint256 tokenId, uint256 amount);
    event Token1155Withdrawed(address indexed sender, address indexed recipient, address indexed token, uint256 tokenId, uint256 amount);
    event Token1155BatchDeposited(address indexed sender, address indexed token, uint256[] tokenIds, uint256[] amounts);
    event Token1155BatchWithdrawed(address indexed sender, address indexed recipient, address indexed token, uint256[] tokenIds, uint256[] amounts);
    event ETHDeposited(address indexed sender, uint256 amount);
    event ETHWithdrawed(address indexed sender, address indexed recipient, uint256 amount);
    event ManagerCall(address indexed sender, address indexed contractAddr, uint256 value, bytes data);
    
    constructor(address _owner) {
        if(_owner == address(0)) revert InvalidOwnerAddress();
        Ownable.transferOwnership(_owner);
    }

    receive() external payable {
        // do nothing
    }

    /// @notice Assign filter mapper contract
    /// @notice Only the owner can do this
    /// @param _filterMapper address of the filter mapper contract
    function assignFilterMapper(address _filterMapper) external onlyOwner {
        config.filterMapper = IFilterMapper(_filterMapper);
        emit FilterMapperChanged(msg.sender, _filterMapper);
    }

    /// @notice Assign fund manager
    /// @notice Only the owner can do this
    /// @param _manager fund manager address
    function assignManager(address _manager) external onlyOwner {
        config.manager = _manager;
        emit ManagerChanged(msg.sender, _manager);
    }

    /// @notice Assign investor
    /// @notice Only the owner can do this
    /// @param _investor investor address
    function assignInvestor(address _investor) external onlyOwner {
        config.investor = _investor;
        emit InvestorChanged(msg.sender, _investor);
    }

    /// @notice Set to allow or disallow manager signature validation
    /// @notice Only the owner can do this
    /// @param _allow true to allow, false to disallow
    /// @notice This is for EIP-1271 signature validation.
    function setAllowManagerSignature(bool _allow) external onlyOwner {
        config.allowManagerSignature = _allow;
        emit AllowManagerSignatureChanged(msg.sender, _allow);
    }

    /// @notice Deposit ERC20 tokens
    /// @notice Only the investor can do this
    /// @param _token address of the ERC-20 token
    /// @param _amount amount of the token to deposit
    function deposit(address _token, uint256 _amount) external nonReentrant onlyInvestor {
        SafeERC20.safeTransferFrom(IERC20(_token), msg.sender, address(this), _amount);
        emit TokenDeposited(msg.sender, _token, _amount);
    }

    /// @notice Withdraw ERC20 tokens
    /// @notice Only the investor can do this
    /// @param _token address of the ERC-20 token
    /// @param _amount amount of the token to withdraw
    function withdraw(address _recipient, address _token, uint256 _amount) external nonReentrant onlyInvestor {
        if (_recipient == address(0)) revert InvalidRecipientAddress();

        SafeERC20.safeTransfer(IERC20(_token), _recipient, _amount);
        emit TokenWithdrawed(msg.sender, _recipient, _token, _amount);
    }

    /// @notice Deposit ERC721 tokens
    /// @notice Only the investor can do this
    /// @param _token address of the NFT
    /// @param _tokenId the NFT to deposit
    function deposit721(address _token, uint256 _tokenId) external nonReentrant onlyInvestor {
        IERC721(_token).safeTransferFrom(msg.sender, address(this), _tokenId);
        emit Token721Deposited(msg.sender, _token, _tokenId);
    }

    /// @notice Withdraw ERC721 tokens
    /// @notice Only the investor can do this
    /// @param _token address of the NFT
    /// @param _tokenId the NFT to withdraw
    function withdraw721(address _recipient, address _token, uint256 _tokenId) external nonReentrant onlyInvestor {
        if (_recipient == address(0)) revert InvalidRecipientAddress();

        IERC721(_token).safeTransferFrom(address(this), _recipient, _tokenId);
        emit Token721Withdrawed(msg.sender, _recipient, _token, _tokenId);
    }

    /// @notice Deposit ERC1155 tokens
    /// @notice Only the investor can do this
    /// @param _token address of the token contract
    /// @param _tokenId the token to deposit
    /// @param _amount amount to deposit
    function deposit1155(address _token, uint256 _tokenId, uint256 _amount) external nonReentrant onlyInvestor {
        IERC1155(_token).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        emit Token1155Deposited(msg.sender, _token, _tokenId, _amount);
    }

    /// @notice Withdraw ERC1155 tokens
    /// @notice Only the investor can do this
    /// @param _token address of the token contract
    /// @param _tokenId the token to withdraw
    /// @param _amount amount to withdraw
    function withdraw1155(address _recipient, address _token, uint256 _tokenId, uint256 _amount) external nonReentrant onlyInvestor {
        if (_recipient == address(0)) revert InvalidRecipientAddress();

        IERC1155(_token).safeTransferFrom(address(this), _recipient, _tokenId, _amount, "");
        emit Token1155Withdrawed(msg.sender, _recipient, _token, _tokenId, _amount);
    }

    /// @notice Batch deposit ERC1155 tokens
    /// @notice Only the investor can do this
    /// @param _token address of the token contract
    /// @param _tokenIds the token to deposit
    /// @param _amounts amount to deposit
    function deposit1155Batch(address _token, uint256[] calldata _tokenIds, uint256[] calldata _amounts) external nonReentrant onlyInvestor {
        IERC1155(_token).safeBatchTransferFrom(msg.sender, address(this), _tokenIds, _amounts, "");
        emit Token1155BatchDeposited(msg.sender, _token, _tokenIds, _amounts);
    }

    /// @notice Batch withdraw ERC1155 tokens
    /// @notice Only the investor can do this
    /// @param _token address of the token contract
    /// @param _tokenIds the token to withdraw
    /// @param _amounts amount to withdraw
    function withdraw1155Batch(address _recipient, address _token, uint256[] calldata _tokenIds, uint256[] calldata _amounts) external nonReentrant onlyInvestor {
        if (_recipient == address(0)) revert InvalidRecipientAddress();

        IERC1155(_token).safeBatchTransferFrom(address(this), _recipient, _tokenIds, _amounts, "");
        emit Token1155BatchWithdrawed(msg.sender, _recipient, _token, _tokenIds, _amounts);
    }    

    /// @notice Deposit ETH
    /// @notice Only the investor can do this
    /// @param _amount amount of the token to deposit
    function depositETH(uint256 _amount) external payable onlyInvestor {
        if (msg.value != _amount) revert IncorrectValue();
        emit ETHDeposited(msg.sender, _amount);
    }

    /// @notice Withdraw ETH
    /// @notice Only the investor can do this
    /// @param _amount amount of ETH to withdraw
    function withdrawETH(address payable _recipient, uint256 _amount) external nonReentrant onlyInvestor {
        if (_recipient == address(0)) revert InvalidRecipientAddress();

        Address.sendValue(_recipient, _amount);
        emit ETHWithdrawed(msg.sender, _recipient, _amount);
    }

    /// @notice Call smart contract from vault
    /// @notice Only manager can do this
    /// @notice Only smart contracts and functions whitelisted in the filters can be called
    /// @param _contract smart contract address
    /// @param _value ETH to send with the call
    /// @param _args function signature and parameters
    function managerCall(address _contract, uint256 _value, bytes memory _args) external nonReentrant onlyManager {
        if (address(config.filterMapper) == address(0)) revert FilterMapperNotAssigned();
        _internalManagerCall(_contract, _value, _args);
    }

    /// @notice Batch call smart contract from vault
    /// @notice Only manager can do this
    /// @notice Only smart contracts and functions whitelisted in the filters can be called
    /// @param _contracts smart contract addresses
    /// @param _values ETH to send with the call
    /// @param _args function signature and parameters
    function managerCallMulti(address[] memory _contracts, uint256[] memory _values, bytes[] memory _args) external nonReentrant onlyManager {
        if (address(config.filterMapper) == address(0)) revert FilterMapperNotAssigned();
        if (_contracts.length != _values.length || _contracts.length != _args.length) revert InconsistentParamsLengths();
        
        uint256 i;
        for (i = 0; i < _contracts.length; i++) {
            _internalManagerCall(_contracts[i], _values[i], _args[i]);
        }
    }

    function _internalManagerCall(address _contract, uint256 _value, bytes memory _args) internal {
        // get filter for _contract
        address filter = config.filterMapper.mapFilter(_contract);
        if (filter == address(0)) revert ContractNotInWhitelist();
        if (!Address.isContract(filter)) revert InvalidFilter();

        // call filter to check _args
        (bool success, bytes memory returndata) = filter.staticcall(_args);
        if (!success) {
            _forwardRevert(returndata);
        }

        if (returndata.length == 0) revert InvalidFilterReturnValue();
        if (abi.decode(returndata, (bytes4)) != 0x59faaa03) revert InvalidFilterReturnValue();

        // actually call _contract if filter is successful
        if (!Address.isContract(_contract)) revert InvalidContractAddress();
        (success, returndata) = _contract.call{ value: _value }(_args);
        if (!success) {
            _forwardRevert(returndata);
        }

        emit ManagerCall(msg.sender, _contract, _value, _args);
    }

    function _forwardRevert(bytes memory result) internal pure {
        // forward revert from filter
        // from OpenZeppelin's Address.sol
        // works with both revert string and custom error
        if (result.length == 0) revert();
        assembly {
            revert(add(32, result), mload(result))
        }
    }

    /// @notice EIP-1271 signature validation
    /// @notice Always validates owner's signature
    /// @notice Optionally (depends on allowManagerSignature settings) validates manager's signature
    /// @param _hash data to sign
    /// @param _signature signature
    /// @return magicNumber returns 0x1626ba7e if valid, 0xffffffff if invalid
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4 magicNumber) {
        (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(_hash, _signature);
        if (err != ECDSA.RecoverError.NoError) {
            return 0xffffffff;                  // not valid signature
        }

        if (signer == Ownable.owner() ||
            (config.allowManagerSignature && signer == config.manager)) {
            return 0x1626ba7e;                  // valid signature
        }

        return 0xffffffff;
    }

    // IERC721Receiver
    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
    // IERC1155Receiver
    function onERC1155Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*id*/,
        uint256 /*value*/,
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;        
    }

    function onERC1155BatchReceived(
        address /*operator*/,
        address /*from*/,
        uint256[] calldata /*ids*/,
        uint256[] calldata /*values*/,
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    // modifiers

    /**
     * @dev Throws if called by any account other than the investor.
     */
    modifier onlyInvestor() {
        if (msg.sender != config.investor) revert CallerIsNotInvestor();
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        if (msg.sender != config.manager) revert CallerIsNotManager();
        _;
    }    
}