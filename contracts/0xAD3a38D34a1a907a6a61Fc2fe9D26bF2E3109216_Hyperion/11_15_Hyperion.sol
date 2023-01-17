//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

error Paused();
error SoldOut();
error SaleNotStarted();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error MintedOut();
error MaxMints();
error ArraysDontMatch();

contract Hyperion is ERC721AQueryable, Ownable,OperatorFilterer,ERC2981{
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint constant public maxSupply = 444;
    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = ".json";

    //0 -> whitelist :: 1->public

    address private signer = 0x44DC5eC08715A70AD4b7FA97DDba41130867074f;
    bool public revealed = true;
    bool operatorFilteringEnabled;
    //False on mainnet
    enum SaleStatus  {INACTIVE,GROUP1,GROUP2}
    SaleStatus public saleStatus = SaleStatus.INACTIVE;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor()
        ERC721A("Hyperion", "HYPR")
    {
        setNotRevealedURI("ipfs://QmRRQrJPnyK6wxSvBPu64Pb7PCdCKKx72mTvfUr5omrPJg");
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
        //First 200 Go To Treasury
    }

    function airdrop(address[] calldata accounts,uint[] calldata amounts) external onlyOwner{
        if(accounts.length != amounts.length) revert ArraysDontMatch();
        uint supply = totalSupply();
        for(uint i; i<accounts.length;i++)  {
            if(supply + amounts[i] > maxSupply) revert SoldOut();
            supply += amounts[i];
            _mint(accounts[i],amounts[i]);
        }     
    }

    /*///////////////////////////////////////////////////////////////
                          MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function group1Mint(uint amount,uint max, bytes memory signature) external {
        if(saleStatus != SaleStatus.GROUP1) revert SaleNotStarted();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        bytes32 hash = keccak256(abi.encodePacked("G1",max,_msgSender()));
        if(hash.toEthSignedMessageHash().recover(signature)!=signer) revert NotWhitelisted();
        if(getNumMintedGroup1(_msgSender()) + amount > max) revert MaxMints();
        _mint(_msgSender(),amount);
    }
    function group2Mint(uint amount,uint max, bytes memory signature) external {
        if(saleStatus != SaleStatus.GROUP2) revert SaleNotStarted();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        bytes32 hash = keccak256(abi.encodePacked("G2",max,_msgSender()));
        if(hash.toEthSignedMessageHash().recover(signature)!=signer) revert NotWhitelisted();
        if(getNumMintedGroup2(_msgSender()) + amount > max) revert MaxMints();
        _mint(_msgSender(),amount);
    }
    
  
       function getNumMintedGroup1(address account) public view returns(uint){
        return _numberMinted(account);
    }
        function getNumMintedGroup2(address account) public view returns(uint){
        return uint(_getAux(account));
    }
    /*///////////////////////////////////////////////////////////////
                          MINTING UTILITIES
    //////////////////////////////////////////////////////////////*/
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setGroup1On() external onlyOwner {
        saleStatus = SaleStatus.GROUP1;
    }
    function setGroup2On() external onlyOwner {
        saleStatus = SaleStatus.GROUP2;
    }

    function turnSalesOff() external onlyOwner{
        saleStatus = SaleStatus.INACTIVE;
    }
 
    function switchReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }
    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
    }

    /*///////////////////////////////////////////////////////////////
                                METADATA
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721A,ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _toString(tokenId),uriSuffix))
                : "";
    }

    /*///////////////////////////////////////////////////////////////
                           WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/
      function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
 //----ClosedSea Functions ----------------
 function setApprovalForAll(address operator, bool approved) public override(IERC721A,ERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
}

function approve(address operator, uint256 tokenId) public payable  override(IERC721A,ERC721A) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
}
 function transferFrom(address from, address to, uint256 tokenId)
    public
    payable
    override (IERC721A, ERC721A)
    onlyAllowedOperator(from)
{
    super.transferFrom(from, to, tokenId);
}

function safeTransferFrom(address from, address to, uint256 tokenId)
    public
    payable
    override (IERC721A, ERC721A)
    onlyAllowedOperator(from)
{
    super.safeTransferFrom(from, to, tokenId);
}

function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override (IERC721A, ERC721A)
    onlyAllowedOperator(from)
{
    super.safeTransferFrom(from, to, tokenId, data);
}

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override (IERC721A, ERC721A, ERC2981)
    returns (bool)
{
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
}

function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
}

function setOperatorFilteringEnabled(bool value) public onlyOwner {
    operatorFilteringEnabled = value;
}

function _operatorFilteringEnabled() internal view override returns (bool) {
    return operatorFilteringEnabled;
}

function _isPriorityOperator(address operator) internal pure override returns (bool) {
    // OpenSea Seaport Conduit:
    // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
    // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
    return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
}
   

}