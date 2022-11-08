// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IBridge.sol";

/// @title ERC721 Peg contract on ethereum
/// @author Root Network
/// @notice Provides an Eth/Root network ERC721/RN721 peg
///  - depositing: lock ERC721 tokens to redeem Root network RN721 tokens 1:1
///  - withdrawing: burn or lock RN721 to redeem ERC721 tokens 1:1
contract ERC721Peg is Ownable, ERC721Holder, IBridgeReceiver, ERC165 {

    uint8 constant MAX_BRIDGABLE_CONTRACT_ADDRESSES = 10;
    uint8 constant MAX_BRIDGABLE_CONTRACT_TOKENS = 50;

    // whether the peg is accepting deposits
    bool public depositsActive;
    // whether the peg is accepting withdrawals
    bool public withdrawalsActive;
    // whether the peg can forward data sent from erc721 calls
    bool public erc721CallForwardingActive;
    //  Bridge contract address
    IBridge public bridge;
    // the (pseudo) pallet address this contract is paried with on root
    address public palletAddress = address(0x6D6F646c726e2F6E667470670000000000000000);

    event DepositActiveStatus(bool indexed active);
    event WithdrawalActiveStatus(bool indexed active);
    event ERC721Called(address indexed token, bytes input, bytes data);
    event ERC721CallForwardingActiveStatus(bool indexed active);
    event BridgeAddressUpdated(address indexed bridge);
    event PalletAddressUpdated(address indexed palletAddress);
    event Deposit(address indexed _address, address[] indexed tokenAddresses, uint256[][] indexed tokenIds, address destination);
    event Withdraw(address indexed _address, address[] indexed tokenAddresses, uint256[][] indexed tokenIds);
    event AdminWithdraw(address indexed _address, address[] indexed tokenAddresses, uint256[][] indexed tokenIds);

    constructor(IBridge _bridge) {
        bridge = _bridge;
    }

    /// @notice Deposit token ids of erc721 NFTs.
    /// @notice The pegged version of the erc721 NFTs will be claim-able on Root network.
    /// @param _tokenAddresses The addresses of the erc721 NFTs to deposit
    /// @param _tokenIds The ids of the erc721 NFTs to deposit
    /// @param _destination The address to send the pegged ERC721 tokens to on Root network
    function deposit(address[] calldata _tokenAddresses, uint256[][] calldata _tokenIds, address _destination) payable external {
        require(depositsActive, "ERC721Peg: deposits paused");
        require(_tokenAddresses.length == _tokenIds.length, "ERC721Peg: tokenAddresses and tokenIds must be same length");
        require(_tokenAddresses.length <= MAX_BRIDGABLE_CONTRACT_ADDRESSES, "ERC721Peg: too many token addresses");
        require(msg.value >= bridge.sendMessageFee(), "ERC721Peg: insufficient bridge fee");

        // send NFTs to this contract
        for (uint256 i = 0; i < _tokenAddresses.length; ++i) {
            address tokenAddress = _tokenAddresses[i];
            uint256[] memory tokenIds = _tokenIds[i];
            require(tokenIds.length <= MAX_BRIDGABLE_CONTRACT_TOKENS, "ERC721Peg: too many token ids");
            for (uint256 j = 0; j < tokenIds.length; j++) {
                uint256 tokenId = tokenIds[j];
                require(tokenId < type(uint32).max, "ERC721Peg: tokenId too large");
                IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);
            }
        }

        emit Deposit(msg.sender, _tokenAddresses, _tokenIds, _destination);

        // send message to bridge
        bytes memory message = abi.encode(1, _tokenAddresses, _tokenIds, _destination); // msg type 1 is deposit
        bridge.sendMessage{ value: msg.value }(palletAddress, message);
    }

    function onMessageReceived(address _source, bytes calldata _message) external override {
        // only accept calls from the bridge contract
        require(msg.sender == address(bridge), "ERC721Peg: only bridge can call");
        // only accept messages from the peg pallet
        require(_source == palletAddress, "ERC721Peg: source must be peg pallet address");

        (address[] memory tokenAddresses, uint256[][] memory tokenIds, address recipient) = abi.decode(_message, (address[], uint256[][], address));
        _withdraw(tokenAddresses, tokenIds, recipient);
    }

    /// @notice Withdraw tokens from this contract
    /// @notice Requires signatures from a threshold of current Root network validators.
    function _withdraw(address[] memory _tokenAddresses, uint256[][] memory _tokenIds, address _recipient) internal {
        require(withdrawalsActive, "ERC721Peg: withdrawals paused");
        require(_tokenAddresses.length == _tokenIds.length, "ERC721Peg: tokenAddresses and tokenIds must be same length");

        // send NFTs to user
        for (uint256 i = 0; i < _tokenAddresses.length; ++i) {
            address tokenAddress = _tokenAddresses[i];
            uint256[] memory tokenIds = _tokenIds[i];
            for (uint256 j = 0; j < tokenIds.length; j++) {
                IERC721(tokenAddress).safeTransferFrom(address(this), _recipient, tokenIds[j]);
            }
        }

        emit Withdraw(_recipient, _tokenAddresses, _tokenIds);
    }

    /// @notice Calls a function on the ERC721 contract and forwards the result to the bridge as a message
    function callERC721(address _tokenAddress, bytes calldata _input) external payable {
        require(erc721CallForwardingActive, "ERC721Peg: erc721 call forwarding paused");
        require(msg.value >= bridge.sendMessageFee(), "ERC721Peg: insufficient bridge fee");

        (bool success, bytes memory data) = _tokenAddress.staticcall(_input);
        require(success, "ERC721Peg: ERC721 call failed");

        emit ERC721Called(_tokenAddress, _input, data);

        // send message to bridge
        bytes memory message = abi.encode(2, _tokenAddress, _input, data); // msg type 2 is call erc721
        bridge.sendMessage{ value: msg.value }(palletAddress, message);
    }

    /// @dev See {IERC165-supportsInterface}. Docs: https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IBridgeReceiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ============================================================================================================= //
    // ============================================== Admin functions ============================================== //
    // ============================================================================================================= //

    function setDepositsActive(bool _active) external onlyOwner {
        depositsActive = _active;
        emit DepositActiveStatus(_active);
    }

    function setWithdrawalsActive(bool _active) external onlyOwner {
        withdrawalsActive = _active;
        emit WithdrawalActiveStatus(_active);
    }

    function setERC721CallForwardingActive(bool _active) external onlyOwner {
        erc721CallForwardingActive = _active;
        emit ERC721CallForwardingActiveStatus(_active);
    }

    function setBridgeAddress(IBridge _bridge) external onlyOwner {
        bridge = _bridge;
        emit BridgeAddressUpdated(address(_bridge));
    }

    function setPalletAddress(address _palletAddress) external onlyOwner {
        palletAddress = _palletAddress;
        emit PalletAddressUpdated(_palletAddress);
    }

    function adminEmergencyWithdraw(address[] memory _tokenAddresses, uint256[][] memory _tokenIds, address _recipient) external onlyOwner {
        _withdraw(_tokenAddresses, _tokenIds, _recipient);
        emit AdminWithdraw(_recipient, _tokenAddresses, _tokenIds);
    }
}