/*
 /$$                           /$$                                            
| $$                          | $$                                            
| $$$$$$$   /$$$$$$   /$$$$$$$| $$   /$$                                      
| $$__  $$ |____  $$ /$$_____/| $$  /$$/                                      
| $$  \ $$  /$$$$$$$| $$      | $$$$$$/                                       
| $$  | $$ /$$__  $$| $$      | $$_  $$                                       
| $$  | $$|  $$$$$$$|  $$$$$$$| $$ \  $$                                      
|__/  |__/ \_______/ \_______/|__/  \__/                                      
                                                                              
                                                                              
                                                                              
               /$$     /$$                                                    
              | $$    | $$                                                    
             /$$$$$$  | $$$$$$$   /$$$$$$                                     
            |_  $$_/  | $$__  $$ /$$__  $$                                    
              | $$    | $$  \ $$| $$$$$$$$                                    
              | $$ /$$| $$  | $$| $$_____/                                    
              |  $$$$/| $$  | $$|  $$$$$$$                                    
               \___/  |__/  |__/ \_______/                                    
                                                                              
                                                                              
                                                                              
                                   /$$                                 /$$    
                                  | $$                                | $$    
                          /$$$$$$ | $$  /$$$$$$  /$$$$$$$   /$$$$$$  /$$$$$$  
                         /$$__  $$| $$ |____  $$| $$__  $$ /$$__  $$|_  $$_/  
                        | $$  \ $$| $$  /$$$$$$$| $$  \ $$| $$$$$$$$  | $$    
                        | $$  | $$| $$ /$$__  $$| $$  | $$| $$_____/  | $$ /$$
                        | $$$$$$$/| $$|  $$$$$$$| $$  | $$|  $$$$$$$  |  $$$$/
                        | $$____/ |__/ \_______/|__/  |__/ \_______/   \___/  
                        | $$                                                  
                        | $$                                                  
                        |__/ 







                 we love

     __       .__   __                 .__          
    |__| ____ |  |_/  |_    ____  ____ |  | _____   
    |  |/  _ \|  |\   __\ _/ ___\/  _ \|  | \__  \  
    |  (  <_> )  |_|  |   \  \__(  <_> )  |__/ __ \_
/\__|  |\____/|____/__|    \___  >____/|____(____  /
\______|                       \/                \/ 

*/


// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;



import "ERC721A.sol";
import "DefaultOperatorFilterer.sol";
import "Ownable.sol";
import "ERC2981.sol";
import "ReentrancyGuard.sol";
import "MerkleProof.sol";
import "ERC20Burnable.sol";

interface HackStake {
    function isStaked(uint256 tokenId) external returns(bool);
    function stake(uint256 tokenId) external;
    function unstake(uint256 tokenId) external;
    function claim(uint256 tokenId) external;
    function getStakeTime(uint256 tokenId) external returns(uint256);
    function claimReward() external;
}

interface HackNote {
    function mint(uint256 tokenId, string calldata note) external;
    function getNoteMessage(uint256 tokenId) external returns(string memory);
}

interface HackBurnable {
    function burn(uint256 tokenId) external;
}

contract h4cktheplan3t is ERC721A, ERC2981, DefaultOperatorFilterer, Ownable, ReentrancyGuard{
    
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
    uint256 public Hack_PRICE;

    HackStake private hackContract;
    HackNote private hackNote;
    ERC20Burnable private hackToken;
    HackBurnable private hackBurn;

    // Metadata
    mapping(uint256 => string) private _baseUri;
    mapping(uint256 => uint256) private _revealStages;
    mapping(uint256 => uint256) private _revealCosts;
    mapping(uint256 => bool) private _claimedStakeReward;
    mapping(uint256 => uint256) private _boosts;

    modifier revertIfStaked(uint256 tokenId) {
        require(hackContract.isStaked(tokenId) == false, "Hack is staked");
        _;
    }

    constructor(string memory _placeholderUri, uint16 _maxSupply, uint16 _freeSupply, uint16 _maxPerTx,
        uint16 _maxPerWallet, uint16 _maxFreePerTx, uint16 _maxFreePerWallet, uint16 _teamSupply, uint256 _hackPrice) ERC721A("h4cktheplan3t", "Hack"){
        _baseUri[0] = _placeholderUri;
        MAX_SUPPLY = _maxSupply;
        FREE_SUPPLY = _freeSupply;
        MAX_PER_TX = _maxPerTx;
        MAX_PER_WALLET = _maxPerWallet;
        MAX_FREE_PER_TX = _maxFreePerTx;
        MAX_FREE_PER_WALLET = _maxFreePerWallet;
        TEAM_SUPPLY = _teamSupply;
        Hack_PRICE = _hackPrice;
    }



    function mint(uint256 quantity) external payable nonReentrant{
        require(MINT_STAGE == 2, "Cannot hack yet");
        require(msg.sender == tx.origin, "Contracts cannot hack");
        require(quantity <= MAX_PER_TX, "Too much at once");
        require(_numberMinted(msg.sender) < MAX_PER_WALLET, "Too much");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Out of");
        require(quantity * Hack_PRICE == msg.value, "Wrong price");

        _mint(msg.sender, quantity);
    }

    function freeMint(uint256 quantity) external nonReentrant {
        require(MINT_STAGE >= 1, "Cannot hack yet");
        require(msg.sender == tx.origin, "Contracts cannot hack");
        require(_totalMinted() + quantity <= FREE_SUPPLY, "Out of Hack");
        require(quantity <= MAX_FREE_PER_TX, "Too much free Hack at once");
        require(_numberMinted(msg.sender) < MAX_FREE_PER_WALLET, "Too much free Hack");

        _mint(msg.sender, quantity);
    }

    function teamMint(uint16 quantity) external onlyOwner {
        require(TEAM_MINTED + quantity <= TEAM_SUPPLY, "Cannot surpass team supply");
        require(TEAM_MINTED + quantity + _totalMinted() <= MAX_SUPPLY, "Cannot exceed max supply");
        TEAM_MINTED += quantity;
        _mint(msg.sender, quantity);
    }

    function finalizeNote(uint256 tokenId, string calldata note) external nonReentrant{
        require(NOTES_ENABLED == true, "Not hacking hard enough yet");
        require(ownerOf(tokenId) == msg.sender, "Hack not owned by you");
        require(bytes(note).length <= 140, "Note too long");
        require(hackNote != HackNote(address(0)), "Note not ready yet");

        hackNote.mint(tokenId, note);
    }

    function revealNextStage(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Hack not owned by you");
        
        uint256 tokenStage = _revealStages[tokenId] + 1;

        require(tokenStage <= REVEAL_STAGE, "Hack not ready to reveal");
        require(hackToken.balanceOf(msg.sender) >= _revealCosts[tokenStage], "Hack needs hack to reveal");

        hackToken.burnFrom(msg.sender, _revealCosts[tokenStage]);
        _revealStages[tokenId] = tokenStage;
    }

    function stake(uint256[] calldata tokenIds) external nonReentrant{
        require(STAKING_ENABLED == true, "Hack not long enough yet");
        require(hackContract != HackStake(address(0)), "Hack not ready yet");

        for(uint256 i; i < tokenIds.length; i++){
            if(ownerOf(tokenIds[i]) != msg.sender){
                continue;
            }
            hackContract.stake(tokenIds[i]);
        }
    }

    function claim(uint256[] calldata tokenIds) external nonReentrant {
        require(STAKING_ENABLED == true, "Hack not long enough yet");
        require(hackContract != HackStake(address(0)), "Hack not ready yet");

        for(uint256 i; i < tokenIds.length; i++){
            if(ownerOf(tokenIds[i]) != msg.sender){
                continue;
            }
            hackContract.claim(tokenIds[i]);
        }
    }

    function unstake(uint256[] calldata tokenIds) external nonReentrant{
        require(STAKING_ENABLED == true, "Hack not long enough yet");
        require(hackContract != HackStake(address(0)), "Hack not ready yet");

        for(uint256 i; i < tokenIds.length; i++){
            if(ownerOf(tokenIds[i]) != msg.sender){
                continue;
            }
            hackContract.unstake(tokenIds[i]);
        }
    }

    function claimInstantStakeReward(uint256[] calldata tokenIds) external nonReentrant {
        require(STAKING_ENABLED == true, "Hack not long enough yet");
        require(hackContract != HackStake(address(0)), "Hack not ready yet");

        for(uint256 i; i < tokenIds.length; i++){
            if(ownerOf(tokenIds[i]) != msg.sender){
                continue;
            }

            if(_claimedStakeReward[tokenIds[i]] == true){
                continue;
            }

            _claimedStakeReward[tokenIds[i]] = true;
            hackContract.claimReward();
        }
    }

    function burnHack(uint256[] calldata tokenIds) external nonReentrant {
        require(hackBurn != HackBurnable(address(0)), "Hack not ready yet");

        for(uint256 i; i < tokenIds.length; i++){
            if(ownerOf(tokenIds[i]) != msg.sender){
                continue;
            }

            hackBurn.burn(tokenIds[i]);
        }
    }

    function setHackStakeContract(address _hackContract) external onlyOwner {
        hackContract = HackStake(_hackContract);
    }

    function setHackNoteContract(address _hackNote) external onlyOwner {
        hackNote = HackNote(_hackNote);
    }

    function sethackTokenContract(address _token) external onlyOwner {
        hackToken = ERC20Burnable(_token);
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

    function updateHackPrice(uint256 _HackPrice) external onlyOwner {
        Hack_PRICE = _HackPrice;
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