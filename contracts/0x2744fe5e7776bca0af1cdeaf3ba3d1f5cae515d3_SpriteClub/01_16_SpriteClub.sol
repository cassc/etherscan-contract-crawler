// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// @@@@@@@@@@@@&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@@@
// @@@@@@@@@@&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&@@@@@@@@@@@@@
// @@@@@@@&&&&&G?~^~~~~!YB&##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&GPP5YY5PG#&&&&@@@@@@@@@@
// @@@@@@&#&#5~          :Y&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&#G7.       .^?B&&&&@@@@@@@@
// @@@@@&#&#?    .!YJ!:   :P&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&P  .......    :Y#&#&@@@@@@@
// @@@@@##&?.  .7G&&&#B7.  :G&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&Y. 7PB###B57:    Y#&&&@@@@@@
// @@@@@##&! . .#&&#&&&&?.  .JB&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&BJ~..Y&&&&&&&&&J. . ^5&#&@@@@@@
// @@@@@##&P~  .5#&####&#5^.  :?G#&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&#GJ^  .7&&#&&####&G! . 7G&#&@@@@@@
// @@@@@@##@J  ..Y#&####&&#P5?~..^7G#&&&@@@@@@@@@@@@@@@@@@@@@@@&#&&#Y~.   ^5&&#######&&Y.  :P&#&@@@@@@@
// @@@@@@&&&#J .  J&&#####&&&&&B5~  J#&#&@@@@@@@@@@@@@@@@@@@@&#&&B?:   .~JB&&#######&&J: .:G&#&&@@@@@@@
// @@@@@@@&#&P .. ^5&#####&##&&&&#~. J&##&@@@@@@@@@@@@@@@@@@&#&B?.   :?P#&&########&&7.  :B&&&&@@@@@@@@
// @@@@@@@&#&P..  .7&###########&&B: ^Y&##@@@@@@@@@@@@@@@@@&#&B?    !P&&&&########&#J.  :J&&#&@@@@@@@@@
// @@@@@@&&&&5 .. ~P&###########&#J.  ~&##&@@@@@@@@@@@@@@@@##&Y: .. [email protected]############&#!.  ^G#&&&@@@@@@@@@
// @@@@&&#&#J.   ^P&##########&&#Y    ~&##@@@@@@@@@@@@@@@@@&#&B?    ?&&&&#########&#G:  .7&&#&@@@@@@@@@
// @@@&#&&P~    7B&##########&&P!    !P&#&@@@@@@@@@@@@@@@@@@&#&BJ:.  ~5#&&&########&&J:  .5#&#&@@@@@@@@
// @@&#&#J.   :Y#&##########&&J:   ~P&&#&@@@@@@@@@@@@@@@@@@@@&&&&#PJ^  :?PB&&########&P~  .P#&&&@@@@@@@
// @&#&#Y    ~B&&##########&&7.  .7#&&&&@@@@@@@@@@@@@@@@@@@@@@@&&&&&#5~  .^Y&########&&P^  ^G&#&@@@@@@@
// @&#&P    :J&###########&#J.  .~&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&#?.  :J&&#######&&5 .:P&#&@@@@@@@
// @&#&P  . ~P&###########&#~.  :Y#&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&&:   ^&&#######&&5 .~G&#&@@@@@@@
// @&#&G:   :J&###########&#P:  .!&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#J:  ^&&#######&P~ .:G&#&@@@@@@@
// @&&&&G^   !&&&#######&&#&&7.  .?#&#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&#B^  ^&&#######&B?   7G&&&&@@@@@
// @@&&#&#J^ .7#&&&#####&&##&&Y:   ^P&#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&#B^  ^##&#######&#Y^  ^Y&&#&@@@@
// @@@@&&&&B5~ ^5#&&#########&&P^   ^5&##@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#Y:  ^&&######&&#&&#P7. !G&&&&@@
// @@@@@@&&&&#J  :J#&#########&&P  . ?&##&@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#~.  ~&&##########&&&&5^ .G&&&&@
// @@@@@@@@&#&B.   :J&&########&G..  ?&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#. . ^&&#############&&5  ^G&#&@
// @@@@@@@@@&&#Y. . :#&&#######&G:. .J&##@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#:   :5#&#############@5   P&#&@
// @@@@@@@@@&#&&:   ^&&#######&&P  :5#&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#G^ . .#&#&&########&&G!  .G&#&@
// @@@@@@@@@&#&&:  :J&&######&#Y: ^G&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&&J:  .#&#&&#####&&&B?:  ~G#&&&@
// @@@@@@@@@&#&#:  !#&&####&&B7. :#&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&G~  .#&#######&#P!. :7P&&#&&@@
// @@@@@@@@@&#&#:  !&#####&##^  ^P&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&&7  .#&######&P~  ^YB&&&&&@@@@
// @@@@@@@@@&#&#:  [email protected]#####&#J:  ~&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##&7 .^#&#####&#? .:B&&&&@@@@@@@
// @@@@@@@@@&#&#~. ^P&&###&#~.  !&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#7 .~#&#####&Y^ .Y#&#&@@@@@@@@
// @@@@@@@@@@&###~  :P&&&&&G.  :?&&#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##&5^ .^#&###&&&!  :P#&#&@@@@@@@@
// @@@@@@@@@@@&#&B?.  ~?J?!.   !B&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#&&7.  .G&&&&&#7.  :5#&#&@@@@@@@@
// @@@@@@@@@@@@&#&&G?:..      !P&##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#&&?:  ..75GP?~. . :B#&&&@@@@@@@@
// @@@@@@@@@@@@@&&&&&#BP5YYYYP#&#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#!  .  ...   . .7&&#&@@@@@@@@@
// @@@@@@@@@@@@@@@@&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##&G?:          :J&##&@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&&BP7~~~~~~?5B&&&&@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&@@@@@@@@@@@@@@@@

import './ERC721S.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract SpriteClub is ERC721S, IERC2981, Ownable, Pausable {
    using Strings for uint256;

    bool public isSpritelistSaleActive;
    bool public isRafflelistSaleActive;

    bytes32 public spritelistMerkleRoot;
    bytes32 public rafflelistMerkleRoot;
    mapping(address => uint256) public mintCounts;
    mapping(uint256 => uint256) public spriteAnswers;

    uint16 public royaltyBasisPoints;
    string public collectionURI;
    string internal metadataBaseURI;
    bool public isMetadataFinalized;
    uint256 public mintPrice;

    constructor(string memory initialMetadataBaseURI, string memory initialCollectionURI, uint16 initialRoyaltyBasisPoints, uint256 initialTransactionMintLimit, uint256 initialAddressMintLimit, uint256 initialCollectionSize, uint256 initialMintPrice)
    ERC721S('SpriteClub', 'SPRITE', initialTransactionMintLimit, initialAddressMintLimit, initialCollectionSize)
    Ownable() {
        metadataBaseURI = initialMetadataBaseURI;
        collectionURI = initialCollectionURI;
        royaltyBasisPoints = initialRoyaltyBasisPoints;
        mintPrice = initialMintPrice;
    }

    // Meta

    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
        return (address(this), salePrice * royaltyBasisPoints / 10000);
    }

    function contractURI() external view returns (string memory) {
        return collectionURI;
    }

    // Admin

    function setCollectionURI(string calldata newCollectionURI) external onlyOwner {
        collectionURI = newCollectionURI;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setMetadataBaseURI(string calldata newMetadataBaseURI) external onlyOwner {
        require(!isMetadataFinalized, 'SpriteClub: metadata is now final');
        metadataBaseURI = newMetadataBaseURI;
    }

    function finalizeMetadata() external onlyOwner {
        require(!isMetadataFinalized, 'SpriteClub: metadata is already finalized');
        isMetadataFinalized = true;
    }

    function setRoyaltyBasisPoints(uint16 newRoyaltyBasisPoints) external onlyOwner {
        require(newRoyaltyBasisPoints >= 0, 'SpriteClub: royaltyBasisPoints must be >= 0');
        require(newRoyaltyBasisPoints < 5000, 'SpriteClub: royaltyBasisPoints must be < 5000 (50%)');
        royaltyBasisPoints = newRoyaltyBasisPoints;
    }

    function setIsSpritelistSaleActive(bool newIsSpritelistSaleActive) external onlyOwner {
        require(mintPrice >= 0 || !newIsSpritelistSaleActive, 'SpriteClub: cannot start if mintPrice is 0');
        require(spritelistMerkleRoot != 0, 'SpriteClub: cannot start if spritelistMerkleRoot not set');
        isSpritelistSaleActive = newIsSpritelistSaleActive;
    }

    function setIsRafflelistSaleActive(bool newIsRafflelistSaleActive) external onlyOwner {
        require(mintPrice >= 0 || !newIsRafflelistSaleActive, 'SpriteClub: cannot start if mintPrice is 0');
        require(rafflelistMerkleRoot != 0, 'SpriteClub: cannot start if rafflelistMerkleRoot not set');
        isRafflelistSaleActive = newIsRafflelistSaleActive;
    }

    function setSpritelistMerkleRoot(bytes32 newSpritelistMerkleRoot) external onlyOwner {
        spritelistMerkleRoot = newSpritelistMerkleRoot;
    }

    function setRafflelistMerkleRoot(bytes32 newRafflelistMerkleRoot) external onlyOwner {
        rafflelistMerkleRoot = newRafflelistMerkleRoot;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Metadata

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'SpriteClub: URI query for nonexistent token');
        return string(abi.encodePacked(metadataBaseURI, tokenId.toString(), '.json'));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURI;
    }

    // Minting

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override whenNotPaused() {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "SpriteClub: The caller is another contract");
        _;
    }

    function _generateMerkleLeaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verifyMerkleLeaf(bytes32 merkleLeaf, bytes32 merkleRoot, bytes32[] memory proof) internal pure returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, merkleLeaf);
    }

    function _verifyAnswer(uint256 answer) internal pure returns (bool) {
        if (answer <= 0 || answer > 60000) {
            return false;
        }
        for (uint256 i; i < 5; i++) {
            uint256 value = answer;
            for (uint256 j; j < i; j++) {
                value = value / 10;
            }
            value = value % 10;
            if (value <= 0 || value > 5) {
                return false;
            }
        }
        return true;
    }

    function spritelistMint(uint256 answer, uint256 quantity, bytes32[] calldata proof) public payable callerIsUser {
        require(isSpritelistSaleActive && mintPrice > 0, "SpriteClub: spritelist sale not active");
        require(msg.value >= mintPrice * quantity, "SpriteClub: insufficient payment");
        require(mintCounts[_msgSender()] == 0, "SpriteClub: already claimed");
        require(_verifyMerkleLeaf(_generateMerkleLeaf(_msgSender()), spritelistMerkleRoot, proof), "SpriteClub: invalid proof");
        require(_verifyAnswer(answer), "SpriteClub: answer invalid");
        mintCounts[_msgSender()] += quantity;
        spriteAnswers[currentTokenIndex] = answer;
        _mint(_msgSender(), quantity, false);
    }

    function spritelistMintWithApproval(uint256 answer, uint256 quantity, bytes32[] calldata proof, address[] calldata approvedAddresses) external payable callerIsUser {
        spritelistMint(answer, quantity, proof);
        for (uint256 i; i < approvedAddresses.length; i++) {
            _setApprovalForAll(_msgSender(), approvedAddresses[i], true);
        }
    }

    function rafflelistMint(uint256 answer, bytes32[] calldata proof) public payable callerIsUser {
        require(isRafflelistSaleActive && mintPrice > 0, "SpriteClub: rafflelist sale not active");
        require(msg.value >= mintPrice, "SpriteClub: insufficient payment");
        require(mintCounts[_msgSender()] == 0, "SpriteClub: already claimed");
        require(_verifyMerkleLeaf(_generateMerkleLeaf(_msgSender()), rafflelistMerkleRoot, proof), "SpriteClub: invalid proof");
        require(_verifyAnswer(answer), "SpriteClub: answer invalid");
        mintCounts[_msgSender()] += 1;
        spriteAnswers[currentTokenIndex] = answer;
        _mint(_msgSender(), 1, false);
    }

    function rafflelistMintWithApproval(uint256 answer, bytes32[] calldata proof, address[] calldata approvedAddresses) external payable callerIsUser {
        rafflelistMint(answer, proof);
        for (uint256 i; i < approvedAddresses.length; i++) {
            _setApprovalForAll(_msgSender(), approvedAddresses[i], true);
        }
    }

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        _mint(to, quantity, true);
    }

}