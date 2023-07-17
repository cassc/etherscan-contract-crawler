// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/*
    _     _______  _______  _______  _______  _______  _______  _______  _______ 
 __|_|___(  ____ \(  ___  )(  ____ )(  ____ \(  ____ )(  ___  )(  ____ )(  ____ \
(  _____/| (    \/| (   ) || (    )|| (    \/| (    )|| (   ) || (    )|| (    \/
| (|_|__ | |      | |   | || (____)|| (__    | (____)|| |   | || (____)|| (__    
(_____  )| |      | |   | ||  _____)|  __)   |     __)| |   | ||  _____)|  __)   
/\_|_|) || |      | |   | || (      | (      | (\ (   | |   | || (      | (      
\_______)| (____/\| (___) || )      | (____/\| ) \ \__| (___) || )      | (____/\
   |_|   (_______/(_______)|/       (_______/|/   \__/(_______)|/       (_______/
                                                                                 
                                             

************************************************
*                                              *
*                  Cope Rope                   *
*       https://twitter.com/coperopenft        *
*                                              *
*                                              *
************************************************

*/

import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

interface RopeStake {
    function isStaked(uint256 tokenId) external returns(bool);
    function stake(uint256 tokenId) external;
    function unstake(uint256 tokenId) external;
    function claim(uint256 tokenId) external;
    function getStakeTime(uint256 tokenId) external returns(uint256);
    function claimReward() external;
}

interface RopeNote {
    function mint(uint256 tokenId, string calldata note) external;
    function getNoteMessage(uint256 tokenId) external returns(string memory);
}

interface RopeBurnable {
    function burn(uint256 tokenId) external;
}

contract CopeRope is ERC721A, ERC2981, DefaultOperatorFilterer, Ownable, ReentrancyGuard{
    
    uint16 public MAX_SUPPLY;
    uint16 public FREE_SUPPLY;
    uint16 public MAX_PER_TX;
    uint16 public MAX_PER_WALLET;
    uint16 public MAX_FREE_PER_TX;
    uint16 public MAX_FREE_PER_WALLET;
    uint16 public TEAM_SUPPLY;
    uint16 public REVEAL_STAGE;
    uint16 public MINT_STAGE;
    uint16 private TEAM_MINTED;
    bool public STAKING_ENABLED;
    bool public NOTES_ENABLED;
    uint256 public ROPE_PRICE;

    RopeStake private ropeContract;
    RopeNote private ropeNote;
    ERC20Burnable private ropeToken;
    RopeBurnable private ropeBurn;

    // Metadata
    mapping(uint256 => string) private _baseUri;
    mapping(uint256 => uint256) private _revealStages;
    mapping(uint256 => uint256) private _revealCosts;
    mapping(uint256 => bool) private _claimedStakeReward;
    mapping(uint256 => uint256) private _boosts;

    modifier revertIfStaked(uint256 tokenId) {
        require(ropeContract.isStaked(tokenId) == false, "Rope is staked");
        _;
    }

    constructor(string memory _placeholderUri, uint16 _maxSupply, uint16 _freeSupply, uint16 _maxPerTx,
        uint16 _maxPerWallet, uint16 _maxFreePerTx, uint16 _maxFreePerWallet, uint16 _teamSupply, uint256 _ropePrice) ERC721A("CopeRope", "ROPE"){
        _baseUri[0] = _placeholderUri;
        MAX_SUPPLY = _maxSupply;
        FREE_SUPPLY = _freeSupply;
        MAX_PER_TX = _maxPerTx;
        MAX_PER_WALLET = _maxPerWallet;
        MAX_FREE_PER_TX = _maxFreePerTx;
        MAX_FREE_PER_WALLET = _maxFreePerWallet;
        TEAM_SUPPLY = _teamSupply;
        ROPE_PRICE = _ropePrice;
    }

    /*
        stage 1 be like
        stage 2 be like
        stage 3 be like
    */

    function mint(uint256 quantity) external payable nonReentrant{
        require(MINT_STAGE == 2, "Cannot cope yet");
        require(msg.sender == tx.origin, "Contracts cannot cope");
        require(quantity <= MAX_PER_TX, "Too much rope at once");
        require(_numberMinted(msg.sender) < MAX_PER_WALLET, "Too much rope");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Out of rope");
        require(quantity * ROPE_PRICE == msg.value, "Wrong price for rope");

        _mint(msg.sender, quantity);
    }

    function freeMint(uint256 quantity) external nonReentrant {
        require(MINT_STAGE >= 1, "Cannot cope yet");
        require(msg.sender == tx.origin, "Contracts cannot cope");
        require(_totalMinted() + quantity <= FREE_SUPPLY, "Out of rope");
        require(quantity <= MAX_FREE_PER_TX, "Too much free rope at once");
        require(_numberMinted(msg.sender) < MAX_FREE_PER_WALLET, "Too much free rope");

        _mint(msg.sender, quantity);
    }

    function teamMint(uint16 quantity) external onlyOwner {
        require(TEAM_MINTED + quantity <= TEAM_SUPPLY, "Cannot surpass team supply");
        require(TEAM_MINTED + quantity + _totalMinted() <= MAX_SUPPLY, "Cannot exceed max supply");
        TEAM_MINTED += quantity;
        _mint(msg.sender, quantity);
    }

    function finalizeNote(uint256 tokenId, string calldata note) external nonReentrant{
        require(NOTES_ENABLED == true, "Not coping hard enough yet");
        require(ownerOf(tokenId) == msg.sender, "Rope not owned by you");
        require(bytes(note).length <= 140, "Note too long");
        require(ropeNote != RopeNote(address(0)), "Note not ready yet");

        ropeNote.mint(tokenId, note);
    }

    function revealNextStage(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Rope not owned by you");
        
        uint256 tokenStage = _revealStages[tokenId] + 1;

        require(tokenStage <= REVEAL_STAGE, "Rope not ready to reveal");
        require(ropeToken.balanceOf(msg.sender) >= _revealCosts[tokenStage], "Rope needs cope to reveal");

        ropeToken.burnFrom(msg.sender, _revealCosts[tokenStage]);
        _revealStages[tokenId] = tokenStage;
    }

    function stake(uint256[] calldata tokenIds) external nonReentrant{
        require(STAKING_ENABLED == true, "Rope not long enough yet");
        require(ropeContract != RopeStake(address(0)), "Rope not ready yet");

        for(uint256 i; i < tokenIds.length; i++){
            if(ownerOf(tokenIds[i]) != msg.sender){
                continue;
            }
            ropeContract.stake(tokenIds[i]);
        }
    }

    function claim(uint256[] calldata tokenIds) external nonReentrant {
        require(STAKING_ENABLED == true, "Rope not long enough yet");
        require(ropeContract != RopeStake(address(0)), "Rope not ready yet");

        for(uint256 i; i < tokenIds.length; i++){
            if(ownerOf(tokenIds[i]) != msg.sender){
                continue;
            }
            ropeContract.claim(tokenIds[i]);
        }
    }

    function unstake(uint256[] calldata tokenIds) external nonReentrant{
        require(STAKING_ENABLED == true, "Rope not long enough yet");
        require(ropeContract != RopeStake(address(0)), "Rope not ready yet");

        for(uint256 i; i < tokenIds.length; i++){
            if(ownerOf(tokenIds[i]) != msg.sender){
                continue;
            }
            ropeContract.unstake(tokenIds[i]);
        }
    }

    function claimInstantStakeReward(uint256[] calldata tokenIds) external nonReentrant {
        require(STAKING_ENABLED == true, "Rope not long enough yet");
        require(ropeContract != RopeStake(address(0)), "Rope not ready yet");

        for(uint256 i; i < tokenIds.length; i++){
            if(ownerOf(tokenIds[i]) != msg.sender){
                continue;
            }

            if(_claimedStakeReward[tokenIds[i]] == true){
                continue;
            }

            _claimedStakeReward[tokenIds[i]] = true;
            ropeContract.claimReward();
        }
    }

    function burnRope(uint256[] calldata tokenIds) external nonReentrant {
        require(ropeBurn != RopeBurnable(address(0)), "Rope not ready yet");

        for(uint256 i; i < tokenIds.length; i++){
            if(ownerOf(tokenIds[i]) != msg.sender){
                continue;
            }

            ropeBurn.burn(tokenIds[i]);
        }
    }

    function setRopeStakeContract(address _ropeContract) external onlyOwner {
        ropeContract = RopeStake(_ropeContract);
    }

    function setRopeNoteContract(address _ropeNote) external onlyOwner {
        ropeNote = RopeNote(_ropeNote);
    }

    function setCopeTokenContract(address _token) external onlyOwner {
        ropeToken = ERC20Burnable(_token);
    }

    function setRevealCosts(uint256 stage, uint256 price) external onlyOwner {
        _revealCosts[stage] = price;
    }

    function setBaseURI(uint256 stage, string calldata uriPart) external onlyOwner {
        _baseUri[stage] = uriPart;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri[REVEAL_STAGE];
    }

    function updateRopePrice(uint256 _ropePrice) external onlyOwner {
        ROPE_PRICE = _ropePrice;
    }

    function updateMaxSupply(uint16 _maxSupply) external onlyOwner {
        require(_totalMinted() == 0, "Mint has started");
        MAX_SUPPLY = _maxSupply;
    }

    function updateFreeSupply(uint16 _freeSupply) external onlyOwner {
        FREE_SUPPLY = _freeSupply;
    }

    function updateMaxPerTxn(uint16 _maxPerTxn) external onlyOwner {
        MAX_PER_TX = _maxPerTxn;
    }

    function updateMaxPerWallet(uint16 _maxPerWallet) external onlyOwner {
        MAX_PER_WALLET = _maxPerWallet;
    }

    function updateMaxFreePerWallet(uint16 _maxFreePerWallet) external onlyOwner {
        MAX_FREE_PER_WALLET = _maxFreePerWallet;
    }

    function updateMaxFreePerTxn(uint16 _maxFreePerTxn) external onlyOwner {
        MAX_FREE_PER_TX = _maxFreePerTxn;
    }

    function updateRevealStage(uint16 stage) external onlyOwner {
        REVEAL_STAGE = stage;
    }

    function updateMintStage(uint16 _mintStage) external onlyOwner {
        MINT_STAGE = _mintStage;
    }

    function enableNotes() external onlyOwner {
        NOTES_ENABLED = true;
    }
 
    function enableStaking() external onlyOwner {
        STAKING_ENABLED = true;
    }

    function setDefaultRoyalty(address _receiver, uint96 _fee) public onlyOwner {
        _setDefaultRoyalty(_receiver, _fee);
    }

    function setApprovalForAll(address operator, bool approved) public override
    onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable virtual override
    onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual override
    onlyAllowedOperator(from)
    revertIfStaked(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override
    onlyAllowedOperator(from)
    revertIfStaked(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    virtual
    override
    onlyAllowedOperator(from)
    revertIfStaked(tokenId)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function withdraw(address _withdrawTo) external onlyOwner {
        payable(_withdrawTo).call{value: address(this).balance}("");
    }

    // Off-chain call for future reveals
    function getRevealStage() external view returns (uint256){
        return REVEAL_STAGE;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseUri[REVEAL_STAGE], _intToString(_tokenId)));
    }

    // ERC721A
    function _intToString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}