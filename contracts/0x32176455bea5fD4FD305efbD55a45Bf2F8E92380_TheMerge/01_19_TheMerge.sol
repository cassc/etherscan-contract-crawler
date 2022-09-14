// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IDeck.sol";

contract TheMerge is IDeck, ERC721Enumerable, ERC721Burnable, ERC2981, Ownable, Pausable {
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxCount;
    uint256 private _maxCountPerWallet;
    uint256 public mintFee;
    string private _preReleaseURI;

    uint16 public currentCohort = 1;
    mapping(uint16 => Cohort) public cohorts;

    /// @dev map NFT ID to the cohort
    mapping(uint256 => uint16) private _nftCohorts;
    mapping(uint256 => string) private _cohortBaseURIs;

    /**
     * @param treasury_ The address that will receive all funds for resales
     * @param maxCount_ Max allowed NFTs. e.g. 3333
     * @param maxCountPerWallet_ e.g. 3
     * @param royalties value (between 0 and 10_000). e.g. 10% is 1_000
     * @param tokenName The name of the deck series. e.g. "Awakened Kingdom"
     * @param tokenSymbol The symbol of the deck series. e.g. "AWAKE"
     * @param startingBaseURI The base URI for metadata before the decks are revealed.
     * @param earlyRecipients An array of addresses to receive NFTs (e.g. Just in case!)
     * @param tokenCounts An array of token counts for early recipients
     */
    constructor(
        address payable treasury_,
        uint256 maxCount_,
        uint256 maxCountPerWallet_,
        uint96 royalties,
        string memory tokenName,
        string memory tokenSymbol,
        string memory startingBaseURI,
        address[] memory earlyRecipients,
        uint256[] memory tokenCounts
    ) ERC721(tokenName, tokenSymbol) {
        require(earlyRecipients.length == tokenCounts.length, "Early Recipient arrays mismatch");

        _maxCount = maxCount_;
        _maxCountPerWallet = maxCountPerWallet_;
        _setDefaultRoyalty(treasury_, royalties);
        _preReleaseURI = startingBaseURI;

        for (uint256 i = 0; i < earlyRecipients.length; i++) {
            _mintDeck(tokenCounts[i], earlyRecipients[i]);
        }

        pause();
    }

    /**
     * @dev Step One: Increment cohort so new minters go into the next one and
     * a random value can be set for the previous one.
     **/
    function incrementCohort() public onlyOwner {
        currentCohort += 1;
        emit CohortNumberIncremented(currentCohort);
    }

    /// @inheritdoc	IDeck
    function canMint() external view returns (bool) {
        return !paused();
    }

    /// @inheritdoc	IDeck
    function setCohortRandomValue(uint16 cohortNumber, bytes32 randomHash) external onlyOwner {
        require(cohortNumber < currentCohort, "Can only call for a previous cohort");
        require(bytes32(0) != randomHash, "Random hash cannot be 0");
        Cohort storage cohort = cohorts[cohortNumber];
        require(bytes32(0) == cohort.randomHash, "DECK: Cohort random value has already been set");

        cohort.randomHash = randomHash;
        emit CohortRandomHashSet(cohortNumber, randomHash);
    }

    /// @inheritdoc	IDeck
    function cohortLength(uint16 cohortNumber) external view returns (uint256) {
        return cohorts[cohortNumber].ids.length;
    }

    /// @inheritdoc	IDeck
    function cohortId(uint16 cohortNum, uint256 index) external view returns (uint256) {
        return cohorts[cohortNum].ids[index];
    }

    /// @inheritdoc	IDeck
    function mintDeck(uint256 count) external payable whenNotPaused returns (bool) {
        require(balanceOf(msg.sender) + count <= _maxCountPerWallet, "DECK: Max mint for wallet reached");
        require(_tokenIds.current() + count <= _maxCount, "DECK: Max mint count reached");

        _mintDeck(count, msg.sender);

        return true;
    }

    /// @inheritdoc	IDeck
    function genesisSeed(uint256 tokenId) external view returns (bytes32) {
        require(_exists(tokenId), "DECK: nonexistent token");

        uint16 cid = _nftCohorts[tokenId];
        Cohort memory c = cohorts[cid];
        require(c.randomHash != bytes32(0), "DECK: Cohort has not been initialized yet");

        return keccak256(abi.encodePacked(c.randomHash, tokenId));
    }

    function _mintDeck(uint256 count, address recipient) private returns (bool) {
        Cohort storage cohort = cohorts[currentCohort];
        for (uint256 i; i < count; i++) {
            _tokenIds.increment();
            uint256 nextId = _tokenIds.current();
            _safeMint(recipient, nextId);
            _nftCohorts[nextId] = currentCohort;
            cohort.ids.push(nextId);
        }
        return true;
    }

    /// @inheritdoc	IDeck
    function maxCount() external view returns (uint256) {
        return _maxCount;
    }

    /// @inheritdoc	IDeck
    function maxCountPerWallet() external view returns (uint256) {
        return _maxCountPerWallet;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @inheritdoc	IDeck
    function setBaseURI(string memory newBaseURI, uint256 cohortId_) external onlyOwner {
        _setBaseURI(newBaseURI, cohortId_);
    }

    function _setBaseURI(string memory newBaseURI, uint256 cohortId_) private {
        _cohortBaseURIs[cohortId_] = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "DECK: URI query for nonexistent token");

        uint256 nftCohort = _nftCohorts[tokenId];
        string memory baseURI = _cohortBaseURIs[nftCohort];

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : _preReleaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, id);
    }
}