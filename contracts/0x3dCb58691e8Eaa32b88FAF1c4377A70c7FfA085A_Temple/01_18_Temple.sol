// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/Monotonic.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @custom:security-contact [email protected]
contract Temple is ERC721, ERC721Pausable, Ownable {
    using Monotonic for Monotonic.Increaser;
    Monotonic.Increaser private _totalClaimed;
    address private _beneficiary;
    address public token;

    mapping (address => Blessing[]) private _blessings;

    // merits update
    mapping(address => uint32) public merits;
    uint256 public lastMeritsUpdateTimestamp;

    error TransferNotAllowed();
    event Pray(address prayer, string message, uint256 value, DonateToken token);

    enum DonateToken { ETH, USDT }
    struct Blessing {
        string message;
        uint256 value;
        DonateToken token;
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "The caller is another contract");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _token,
        address payable beneficiary
    ) ERC721(name, symbol) {
        token = _token;
        _beneficiary = beneficiary;
    }


    function totalClaimed() public view returns (uint256) {
        return _totalClaimed.current();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBeneficiary(address payable beneficiary) public onlyOwner {
        _beneficiary = beneficiary;
    }

    function updateMerits(address[] calldata addrs, uint32[] calldata newMerits) public onlyOwner {

        require(addrs.length == newMerits.length, "update data arrays not equal");

        for (uint256 i = 0; i < addrs.length; i++) {
            uint32 oldValue = merits[addrs[i]];
            require( oldValue <= newMerits[i] , "merit can only be increased");
            merits[addrs[i]] = newMerits[i];
        }

        lastMeritsUpdateTimestamp = block.timestamp;
    }
    
    function claim() public callerIsUser {
        /**
         * ##### CHECKS
         */
        // each wallet can claim only one token
        require(balanceOf(_msgSender()) < 1, "each wallet can claim one token");

        /**
         * ##### EFFECTS
         */
        _safeMint(_msgSender(), _totalClaimed.current());
        _totalClaimed.add(1);

        /**
         * ##### INTERACTIONS
         */
        merits[_msgSender()] = 0;
    }

    // donate with ETH
    function pray(
        string memory message
    ) public payable callerIsUser {
        // check is owner
        require(balanceOf(_msgSender()) > 0, "please claim one token first");

        // transfer eth
        if (msg.value > 0) {
            _transfer(_beneficiary, msg.value);
        }

        // save the pray
        Blessing[] storage records =  _blessings[_msgSender()];
        records.push(Blessing({message: message, value: msg.value, token:DonateToken.ETH}));

        // event for sync
        emit Pray( _msgSender(), message, msg.value ,DonateToken.ETH );
    }

    function prayRecord(
        address prayer
    ) public view returns (Blessing[] memory) {
        return _blessings[prayer];
    }

    // donate with USDT
    function prayWithDonateUSDT(
        string memory message,
        uint256 value
    ) public callerIsUser {        
        // check is owner
        require(balanceOf(_msgSender()) > 0, "please claim one token first");

        // transfer usdt
        SafeERC20.safeTransferFrom(IERC20(token), _msgSender(), _beneficiary, value);

        // save the pray
        Blessing[] storage records =  _blessings[_msgSender()];
        records.push(Blessing({message: message, value: value, token:DonateToken.USDT}));
        
        emit Pray( _msgSender(), message, value ,DonateToken.USDT );
    }

    // Stop NFT from being transfered
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override {
        revert TransferNotAllowed();
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        revert TransferNotAllowed();
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        revert TransferNotAllowed();
    }

    function approve(address, uint256) public virtual override {
        revert TransferNotAllowed();
    }

    function setApprovalForAll(address, bool) public virtual override {
        revert TransferNotAllowed();
    }

    function getApproved(uint256) public view virtual override returns (address) {
        return address(0);
    }
    function isApprovedForAll(address, address) public view virtual override returns (bool) {
        return false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
    error TransferFailed();
    function _transfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferFailed();
    }
}