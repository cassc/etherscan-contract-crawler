// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IMultiWalletCallerOperator.sol";
import "./interface/IMinterChild.sol";
import "./interface/IChildStorage.sol";

contract MultiWalletCallerV2 is Ownable {
    IChildStorage private immutable _ChildStorage;

    constructor(address childStorage_) {
        _ChildStorage = IChildStorage(childStorage_);
    }
    receive() external payable {}

    modifier onlyHolder() {
        IMultiWalletCallerOperator(_ChildStorage.operator()).checkHolder(msg.sender);
        _;
    }

    modifier checkId(uint256 _startId, uint256 _endId) {
        IMultiWalletCallerOperator(_ChildStorage.operator()).checkId(_startId, _endId, msg.sender);
        _;
    }

    /**
     * @dev Sets the NFT ID for the caller
     * @param _nftId uint256 ID of the NFT to be set
     */
    function setNFTId(uint256 _nftId) external {
        IMultiWalletCallerOperator(_ChildStorage.operator()).setNFTId(_nftId, msg.sender);
    }

    /**
     * @dev create multiple wallets for a user
     * @param _quantity number of wallets to be created
     */
    function createWallets(uint256 _quantity) external onlyHolder {
        IMultiWalletCallerOperator(_ChildStorage.operator()).createWallets(_quantity, msg.sender);
    }

    /**
     * @dev send ETH to multiple wallets
     * @param _startId start index of wallet to send ETH to
     * @param _endId end index of wallet to send ETH to
     */
    function sendETH(uint256 _startId, uint256 _endId)
        external
        payable
        onlyHolder
        checkId(_startId, _endId)
    {
        IMultiWalletCallerOperator(_ChildStorage.operator()).sendETH{value: msg.value}(_startId, _endId, msg.sender);
    }

    /**
     * @dev send ERC20 tokens to multiple wallets
     * @param _startId start index of wallet to send tokens to
     * @param _endId end index of wallet to send tokens to
     * @param _token address of the token contract
     * @param _amount amount of tokens to be sent
     */
    function sendERC20(
        uint256 _startId,
        uint256 _endId,
        address _token,
        uint256 _amount
    ) external onlyHolder checkId(_startId, _endId) {
        IMultiWalletCallerOperator(_ChildStorage.operator()).sendERC20(_startId, _endId, _token, _amount, msg.sender);
    }

    /**
     * @dev Runs a function of a specified contract for multiple child wallets
     * @param _startId The start id of the wallet
     * @param _endId The end id of the wallet
     * @param _callContract The address of the contract to run the function
     * @param _callData The data of the function to run
     * @param _value The amount of ETH to send to the function
     */
    function run(
        uint256 _startId,
        uint256 _endId,
        address _callContract,
        bytes calldata _callData,
        uint256 _value
    ) external onlyHolder checkId(_startId, _endId) {
        for (uint256 i = _startId; i <= _endId; ) {
            IMinterChild(
                payable(_ChildStorage.child(msg.sender, i))
            ).run_Ozzfvp4CEc(_callContract, _callData, _value);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Runs a function of a specified contract for multiple child wallets, given the function signature
     * @param _startId The start id of the wallet
     * @param _endId The end id of the wallet
     * @param _callContract The address of the contract to run the function
     * @param _signature The signature of the function to run
     * @param _value The amount of ETH to send to the function
     */
    function runWithSelector(
        uint256 _startId,
        uint256 _endId,
        address _callContract,
        string calldata _signature,
        uint256 _value
    ) external onlyHolder checkId(_startId, _endId) {
        bytes memory callData = abi.encodeWithSignature(_signature);
        for (uint256 i = _startId; i <= _endId; ) {
            IMinterChild(
                payable(_ChildStorage.child(msg.sender, i))
            ).run_Ozzfvp4CEc(_callContract, callData, _value);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Withdraws ETH from multiple child wallets to the caller
     * @param _startId The start id of the wallet
     * @param _endId The end id of the wallet
     */
    function withdrawETH(uint256 _startId, uint256 _endId)
        external
        checkId(_startId, _endId)
    {
        IMultiWalletCallerOperator(_ChildStorage.operator()).withdrawETH(_startId, _endId, msg.sender);
    }

    /**
     * @dev Withdraws ERC20 tokens from multiple child wallets to the caller
     * @param _startId The start id of the wallet
     * @param _endId The end id of the wallet
     * @param _contract The address of the ERC20 contract
     */
    function withdrawERC20(
        uint256 _startId,
        uint256 _endId,
        address _contract
    ) external checkId(_startId, _endId) {
        IMultiWalletCallerOperator(_ChildStorage.operator()).withdrawERC20(_startId, _endId, _contract, msg.sender);
    }

    /**
     * @dev Withdraw ERC721 tokens from child wallets with specified token ids.
     * @param _startId The start index of the child wallet.
     * @param _endId The end index of the child wallet.
     * @param _contract The contract address of the ERC721 token.
     * @param _tokenIds The ids of the tokens to be withdrawn.
     */
    function withdrawERC721(
        uint256 _startId,
        uint256 _endId,
        address _contract,
        uint256[] calldata _tokenIds
    ) external checkId(_startId, _endId) {
        IMultiWalletCallerOperator(_ChildStorage.operator()).withdrawERC721(_startId, _endId, _contract, _tokenIds, msg.sender);
    }

    /**
     * @dev Withdraw ERC1155 tokens from child wallets with specified token id.
     * @param _startId The start index of the child wallet.
     * @param _endId The end index of the child wallet.
     * @param _contract The contract address of the ERC1155 token.
     * @param _tokenId The id of the token to be withdrawn.
     */
    function withdrawERC1155(
        uint256 _startId,
        uint256 _endId,
        address _contract,
        uint256 _tokenId
    ) external checkId(_startId, _endId) {
        IMultiWalletCallerOperator(_ChildStorage.operator()).withdrawERC1155(_startId, _endId, _contract, _tokenId, msg.sender);
    }

    /**
     * @dev Only Owner
     * @dev Recover the Ethereum balance to the owner's wallet.
     */
    function recoverETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Only Owner
     * @dev Recover the ERC20 token balance to the owner's wallet.
     * @param _contract The contract address of the ERC20 token.
     */
    function recoverERC20(address _contract) external onlyOwner {
        IERC20(_contract).transfer(
            msg.sender,
            IERC20(_contract).balanceOf(address(this))
        );
    }

    /**
     * @dev Only Owner
     * @dev Recover the ERC721 token to the owner's wallet.
     * @param _contract The contract address of the ERC721 token.
     * @param _tokenId The id of the token to be recovered.
     */
    function recoverERC721(address _contract, uint256 _tokenId)
        external
        onlyOwner
    {
        IERC721(_contract).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
    }

    /**
     * @dev Only Owner
     * @dev Recover the ERC1155 token to the owner's wallet.
     * @param _contract Address of the ERC1155 contract
     * @param _tokenId ID of the token to be recovered
     * @param _amount Amount of the token to be recovered
     * @param _data Additional data for the transfer
     */
    function recoverERC1155(
        address _contract,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) external onlyOwner {
        IERC1155(_contract).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            _amount,
            _data
        );
    }
}