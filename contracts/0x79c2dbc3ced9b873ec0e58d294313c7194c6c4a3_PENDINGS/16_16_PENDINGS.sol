// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IBeforeTokenTransferHandler.sol";

/** 
 * @title THE PENDINGS 
 * @author your friendly neighborhood curion
 * @dev NFT contract for THE PENDINGS, including filter registry hook reference
 */

contract PENDINGS is ERC721Enumerable, Ownable {
    /// @notice Reference to the handler contract for transfer hooks
    using Strings for uint256;

    address public beforeTokenTransferHandler;
    address public paymentSplitterAddress;
    bool public revealed = false;

    string private baseURI;
    string private notRevealedUri; 

    uint256 public currentTokenId = 1;
    uint256 public maxSupply = 999;
    uint256 public mintPhase = 0;
    uint256 public publicMintCost = 0.025 ether;
    uint256 public whitelistMintCost = 0.025 ether;

    mapping (address => bool) public isWhitelisted;

    error MaxSupplyReached();
    error ForwardFailed();
    error QueryForNonexistentToken();
    error WhitelistConditionsNotMet();
    error PublicConditionsNotMet();
    error MintIsClosed();

    constructor(
        address payable _paymentSplitterAddress,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    )
        ERC721("The Pendings", "PDS")
    {
        setPaymentSplitterAddress(_paymentSplitterAddress);
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function totalMintedSoFar() public view returns (uint256) {
        return currentTokenId;
    }

    // fallback payable functions for anything sent to contract not via mint functions
    receive() external payable {} //msg.data must be empty
    fallback() external payable {} //when msg.data is not empty

    function mintPending() payable external {
        address sender = msg.sender;
        if(mintPhase == 0){ revert MintIsClosed(); }
        if(mintPhase == 1 && (!isOnWhitelist(sender) || msg.value < whitelistMintCost)) { revert WhitelistConditionsNotMet(); }
        if(mintPhase == 2 && (msg.value < publicMintCost)) { revert PublicConditionsNotMet(); }
        if(currentTokenId == maxSupply){revert MaxSupplyReached(); }
        
        _safeMint(sender, currentTokenId);
        currentTokenId++;
    }

    function isOnWhitelist(address _addr) public view returns (bool) {
        return isWhitelisted[_addr];
    }

    function addToWhitelist(address[] memory _whitelistAddresses) public onlyOwner {
        for(uint256 i=0; i<_whitelistAddresses.length; i++){
            isWhitelisted[_whitelistAddresses[i]]=true;
        } 
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if( !_exists(tokenId) ) { revert QueryForNonexistentToken(); }
        if(revealed == false) { return notRevealedUri; }
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
            : "";
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setMintPhase(uint256 _phase) public onlyOwner {
        mintPhase = _phase;
    }
    
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setBeforeTokenTransferHandler(address handlerAddress)
        external
        onlyOwner
    {
        beforeTokenTransferHandler = handlerAddress;
    }

    function setPaymentSplitterAddress(address payable _paymentSplitterAddress) public onlyOwner {
        paymentSplitterAddress = payable(_paymentSplitterAddress);
    }

    function setMintPrices(uint256 _whitelistMintCost, uint256 _publicMintCost) public onlyOwner {
        whitelistMintCost = _whitelistMintCost;
        publicMintCost = _publicMintCost;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        if (beforeTokenTransferHandler != address(0)) {
            IBeforeTokenTransferHandler handlerRef = IBeforeTokenTransferHandler(
                    beforeTokenTransferHandler
                );
            handlerRef.beforeTokenTransfer(
                address(this),
                _msgSender(),
                from,
                to,
                tokenId,
                batchSize
            );
        }

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function withdrawERC20FromContract(address _to, address _token) external onlyOwner {
        IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
    }

    function withdrawEthFromContract() external onlyOwner  {
        (bool os, ) = payable(paymentSplitterAddress).call{ value: address(this).balance }('');
        if(!os){ revert ForwardFailed(); }
    }
}