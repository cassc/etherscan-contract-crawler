// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IMultiWalletCallerOperator.sol";
import "./interface/IMinterChild.sol";
import "./interface/IChildStorage.sol";

contract MultiWalletCallerSnipe is Ownable {
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

    function run(
        uint256 _startId,
        address _callContract,
        bytes calldata _callData,
        uint256 _value,
        address _nft,
        uint256 _id,
        uint256 _margin
    ) external onlyHolder checkId(_startId, _startId+_margin) {
        uint256 totalSupply = IERC20(_nft).totalSupply();
        _id -= 2;
        require(totalSupply < _id && totalSupply + _margin > _id, "MultiWalletCallerBaseSnipe: Id error");
        uint256 loop = _id - totalSupply;
        for (uint256 i = _startId; i <= _startId + loop; ) {
            IMinterChild(
                payable(_ChildStorage.child(msg.sender, i))
            ).run_Ozzfvp4CEc(_callContract, _callData, _value);
            unchecked {
                i++;
            }
        }
    }

    function withdrawETH(uint256 _startId, uint256 _endId)
        external
        checkId(_startId, _endId)
    {
        IMultiWalletCallerOperator(_ChildStorage.operator()).withdrawETH(_startId, _endId, msg.sender);
    }

    function withdrawERC721(
        uint256 _startId,
        uint256 _endId,
        uint256 _startNFTId,
        address _contract
    ) external checkId(_startId, _endId) {
        uint256[] memory tokenIds = new uint256[](_startId - _endId + 1);
        
        uint256 counter = 0;
        for (uint256 i = _startId; i <= _endId; ) {
            tokenIds[counter] = _startNFTId;
            unchecked {
                counter++;
                _startNFTId++;
                i++;
            }
        }
        IMultiWalletCallerOperator(_ChildStorage.operator()).withdrawERC721(_startId, _endId, _contract, tokenIds, msg.sender);
    }

    /**
     * @dev Only Owner
     * @dev Recover the Ethereum balance to the owner's wallet.
     */
    function recoverETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}