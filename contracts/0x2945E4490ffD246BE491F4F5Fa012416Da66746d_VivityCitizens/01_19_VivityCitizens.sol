// SPDX-License-Identifier: MIT
// Creator: lohko.io

pragma solidity >=0.8.13;

import {ERC721} from "ERC721.sol";
import {ERC2981} from "ERC2981.sol";
import {Strings} from "Strings.sol";
import {IRandomShuffler} from "IRandomShuffler.sol";
import {ConfirmedOwner} from "ConfirmedOwner.sol";
import {VRFV2WrapperConsumerBase} from "VRFV2WrapperConsumerBase.sol";


error InvalidInput();
error NonExistentTokenURI();

contract VivityCitizens is ERC721, ERC2981, VRFV2WrapperConsumerBase, ConfirmedOwner {
    using Strings for uint256;

    uint256 public constant maxSupply = 5000;

    bool public revealed;

    string private _baseTokenURI;
    string private notRevealedUri;

    address public vivity;

    IRandomShuffler public randomShuffler;

    constructor(
        string memory _initNotRevealedUri,
        address _randomShuffler,
        address _link,
        address _wrapper
    ) ERC721("Vivity Citizens", "Citizens") ConfirmedOwner(msg.sender) VRFV2WrapperConsumerBase(_link, _wrapper)
    {
        notRevealedUri = _initNotRevealedUri;
        randomShuffler = IRandomShuffler(_randomShuffler);
    }

    modifier onlyVivity() {
        if (msg.sender == vivity) {
            _;
        }
    }

    // ========== Claiming ==========

    function claimCitizenship(address _user, uint256 _tokenId) external onlyVivity {
        // Validation
        if (_tokenId == 0 || _tokenId > maxSupply) revert InvalidInput();
        // Interactions
        uint256 _vivityId = randomShuffler.shuffleTokenId(_tokenId);

        _mint(_user, _vivityId);
    }

    // ========== Chainlink ==========

    function getRandomNumber() external onlyOwner returns (uint256 requestId) {
        // callbackGasLimit = 500000, requestConfirmations = 3, numWords = 1
        return requestRandomness(500000, 3, 1);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        randomShuffler.setRandomNumber(_randomWords[0]);
    }

    // ========== Admins ==========

    function setVivity(address _vivity) external onlyOwner {
        vivity = _vivity;
    }

    function setRandomShuffler(address _randomShuffler) external onlyOwner {
        randomShuffler = IRandomShuffler(_randomShuffler);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    // ========== Backup ==========

    function claimCitizenshipBackup(address _user, uint256 _tokenId) external onlyVivity {
        // Set arbitrary vivity citizen id's for vivity token id's in case of shuffling failure
        // Can be only used for unclaimed vivity tokens
        if (_tokenId == 0 || _tokenId > maxSupply) revert InvalidInput();

        _mint(_user, _tokenId);
    }

    // ========== Overrides ==========

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonExistentTokenURI();
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }
}