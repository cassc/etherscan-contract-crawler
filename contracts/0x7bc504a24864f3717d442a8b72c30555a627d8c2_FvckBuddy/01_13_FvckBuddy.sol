// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//   It's another lonely night with nobody but pepe on my side.                      //
//   I touch my pepe’s pipi, it feels alright a tinglish feel, my pants get tight.   //
//   Please find me a fvck buddy tonight.                                            //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract FvckBuddy is ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public isSaleActive;
    string private _baseURIextended;
    mapping (address => bool) hasMinted;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor() ERC721("Fvck Buddy", "FVCKB") {
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) external onlyOwner {
        PROVENANCE = provenance;
    }

    function setSaleActive(bool newState) external onlyOwner {
        isSaleActive = newState;
    }

    function reserve() external onlyOwner {
        require(totalSupply() + 25 <= 1000, "Reserve would exceed max supply of tokens");
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 25; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mint(uint numberOfTokens) external {
        require(isSaleActive, "Sale must be active to mint Tokens");
        require(!hasMinted[msg.sender], "One mint per wallet");
        require(totalSupply() + numberOfTokens <= 1000, "Purchase would exceed max supply of tokens");
        require(!isContract(msg.sender));

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < 1000) {
                _safeMint(msg.sender, mintIndex);
                hasMinted[msg.sender] = true;
            }
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return ERC721.supportsInterface(interfaceId)
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
            || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981
            || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

   function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

}