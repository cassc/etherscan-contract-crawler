// SPDX-License-Identifier: MIT
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                                                                     
//                                                                                                                     //
//                                    .&&,        **&&                                                                 //
//                                    /@@&%#      #@@&%#                                                               //
//                                    (&&@@,%*   #@(@@&/%  ...*,/.(##.                                                 //
//                                    (@#@@&%%% (@@&(@&&#&//*/#(%#/(####/                                              //
//                                    /&%@@@@&&&/&#&@&&&(##(/(((#######(##%                                            //
//                                  * ,&%&*#&&&&%,   /&&%%#((#(((((#########,                                          //
//                                %%,#%&%&%%/&&&%%,(&&&&&%# . ,(((/##(%#%#/###                                         //
//                                 @*@%#@&@@@@&&&&&#&&&&&* #(@(@&%#(#(###((((#(                                        //
//                                 *&&@&&@%@#@@&&#&&&%&//  (&&&&%(%(%%&&(((%%##,                                       //
//                                ,@&@@@@@(#&&&&.&&&#%&@@(@@%@#%#/(((####%%#%###                                       //
//                                .,@@@@*@@@@@@.&&%/&%%%&(#&#*%%,**//##(##%%%%#(#                                      //
//                               ,&&&#&*&%(,*%%%%%,%&&&&&&((#(%&%/***%((((%&##%&/(                                     //
//                              &%@&&(%%%%/*****/%&(&&@((%&#%(#%#(((((####%%#%%%%%*                                    //
//                              %%&&&&&&&&&%&&%(#&&&&@(#####/((((((#%####(%#%%%#%@                                     //
//                              ,%&*%&%/..*&@@@@@@@&&%%**.##%#(((((/#(#/##%#%#%%##                                     //
//                               .#&&&&&&&@@@@@@&@//%/*%%   ...%%%/%%%%%%#%%%##%%//                                    //
//                                   (@@@@@%#(((#.* ..* .  ...... . #%%%#/%%%##%#,&                                    //
//                                 ..,(#%######(%............... ... ##%#*%%%(&%#% *                                   //
//                          */*..,,.,,,*/(##(##,,. ......  .... ,... , *%###%#%##%,..                                  //
//                              ,(*,,,,,//((%%#,,....... ..   ... ,,/*/**##/####&& ,                                   //
//                  .     .....,,**(/(*.,#%(@@%#,................. ..(.&%######( , ,                                   //
//                   ,.........,,*(/*/###%%%%@#(,/.. ..,.........../&%%%#%%(###(@  .                                   //
//                    .    ./* ,,,*%%%%%#*%@@@&&&%*, ...........,%///(###%%####&  .                                    //
//              . ...........**##*,,&&&&&&&%&@&&&&&%%(......(%(((((((//#(*(#*(#*...                                    //
//              .........    .,,*##%/(&&&&&&%@&&&&&&&&&&&&@&&&#&&%%%####(//*/((,... ..                                 //
//                .,....... ..,**/(###%&&&&&&@&&&&&&&&&&&@@@&&&&&&%&&%%#/***,.(.  .  ...                               //
//                #,.. ... . .,,,,*/#%&&&&&@@@&@@&&&&&&&&@@&&&&%&&&&%%(/****,,...,..                                   //
//              ((#,.  .... /((((**/(%&&&@&&@*#&&&&@&&&&@@@&&&&&&&&&&%%##((/(((/,. ...,,,,.       *                    //
//             ##.,,.*##...,(.*(##%###%&@@@@&**,***.%&&&&&&@@@@&%%%&&%%%##(/**,,,....             ##                   //
//           %#(((#/.,.(/*/(//(((#%%&&#%@@@@@&%@&*,*,,,,[email protected]&&@@@&&&&&%%%#(/***,,... ,*.           .#(%                  //
//               ,&&%%%(#***/(,*((((@&@@@@@@@%&%%%&&&%* ..   /#@@@&&&&#,(##((/*,..    ,.         ,(/%%                 //
//               %%%%%%&%%%###%#(*/%**/%#,@@&%%%%%%%%%%%&&#. ./  /&%&%%%%,/(**/*,,..... .       //%//*@(/**            //
//             ##%%#%#%&&&&&&&&&&%((((((.,,(%%%%%%%%%%%%%%%&&/ (* ,##&&&%%((///(/*,*       .(##(//%   *%%%#            //
//        /##* &%%( *,#*.(##@&&%%##&&&%#((#,(%%#%%%%%%&%%%%%&*    (.&#%&%(#(/#//*,,,/#(      ,%%%%%&&&&(               //
//            *&&//****#/##((#%%/%/%&//#@&%%#%%%%%#%&%%%%&%&*.,* @.&%##%%&%#%#*(**.*,#(#         ,&((%%                //
//         (##%%%/(#, (@@/&%#/(%&%##%%@#&&@@%%@%%%%%%%%%%&@.****..%%##%#%###%%%&*,,,(#           #&&@###%%&,           //
//     .(%%####%&(.*.#(#@&&#%&@%((#%%%##@&&&&%%@&&%%%%%%&%/., *./%%%%####%#%#%#%&&%#.            %%%%%&#%&%,           //
//    .#%%%%%%%%(.* [email protected](@(@%&%*#&%(&&&&&&&&#%&&%%&&%%%%&@.,/ / .//&%%%%%%%%%%%&%&&%#             ,&&%&&%%#((((          //
//     .%%%&&%%%& **@@.#&&&&%%//#%###@&%#%//(&&#%%&&%@*&.***.*/,..%%%%%&%%%%%&&&%(.             (&&&&&&##(((/(&        // 
//      #%&&@&&%%%#&%@%&&&&&&&&%###%&@&(/////#&@#@@/(@*(.* .*,.....*#%%%%%%%&&&&%#             (#&&%%&&&@@@&@%#.       //
//        &&&%%##&@@@@@%&&&&%%&&&%,,**@#(//(%&&@&&#*@#/@..*,. ........&#%%%&&#%&&&%(            %&&&&%%&&#(#%%%.       //
//       #&&&&&&&%#(/@%(%@&%&%#%%******#/&&&&%%#@&@*#&..*,.   ...,... .,**&&%&@&*/%%#            &%%%&&&&@&@@@%        //
//       &&&&&%%%&&&#%%((%&(&#@@&@@********///(&&@%%,,.,     ....,......*,%&&&&#(%/#%%#           &&%%%&&@&&%&*        //
//       %&&&&&&&&&&%%&#%/%%%%&%%@@****#****/#%%#&,,,,,.      ...,,......,,&&&&&&%%((               *%%%%&&%%%#        //
//      ,&&%&&&&&&&&&&&%%&%%%%&&%@*********#(/****,,./,         ....,.......,.&&&&&&&%(              .*%##%&&%&&#      //
//                    .     ,       **///***/*//**,,                           .            ,    ,.                    //
//         %@@@@.   @/ ,#@#    *@@@@@#*.**//@@&@@#*,.(@@@@@@@     %@@@@.    ,/@@@@@&       %@.. @/,   .(@@@@@.         //
//        //../#@.  /@ *@&.     ,@@#@@@..**/@@* @@@,   #[email protected]@/@%.  //../#@.    [email protected]@ *@@@.     %@[email protected]%@.   [email protected]@*(&@*         //
//       /@, ,@,    [email protected]@#.   ...*@@,... ***#@@@@#**    .&@ %@*   /@, ,@,   .# @@@#[email protected]     [email protected]@. *@@. ..,*@@,...          //
//        /%.*        @      (@@@@%*. /***/@(**/@@/*, (@@@.      /%.*       %@,  [email protected]*#    //    *.   [email protected]@@@@&.           //
//                           .    .*****//**,,*.%@*,.                     [email protected]      ,@.                                  //
//                                *********,,..   .,@*,,                             .                                 //
//                                   ******,,        ./,,,                                                             //
//                                     **             ...,,.                                                           //
//                                                        ,..                                                          //
//                                                           .,                                                        //
//                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Overborne is ERC721A, Ownable {

    uint256 public MAX_TOKEN_SUPPLY = 10000;

    // whitelist
    uint256 public priceWhitelist = 0.1 ether;
    uint256 public maxMintsPerPersonWhitelist = 3;

    // public
    uint256 public pricePublic = 0.125 ether;
    uint256 public maxMintsPerPersonPublic = 3;

    MintStatus public mintStatus = MintStatus.CLOSED;
    
    enum MintStatus {
        CLOSED,
        WHITELIST,
        PUBLIC
    }
    
    constructor() ERC721A("Overborne", "OVERBORNE") {}

    modifier verifySupply(uint256 _numberOfMints) {
        require(tx.origin == msg.sender,  "No bots");
        //require(_numberOfMints > 0, "Can't mint zero");
        require(_totalMinted() + _numberOfMints <= MAX_TOKEN_SUPPLY, "Exceeds max");

        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _ownershipOf(tokenId).addr == _msgSender() ||
                getApproved(tokenId) == _msgSender(),
            "Not approved nor owner"
        );
        
        _;
    }

    ///////////////////////////
    // -- MINTING --
    ///////////////////////////

    /// @notice Admin reserve tokens
    /// @param recipient Wallet address of recipient
    /// @param _numberOfMints Number of mints
    function reservedMint(address recipient, uint256 _numberOfMints) external onlyOwner verifySupply(_numberOfMints) {
        _safeMint(recipient, _numberOfMints);
    }

    /// @notice Admin reserve many tokens
    /// @param recipients Array of wallet addresses
    /// @param _numberOfMints Number of mints for each receipient
    function reservedMintMany(address[] calldata recipients, uint256 _numberOfMints) external onlyOwner verifySupply(_numberOfMints * recipients.length) {
        uint256 num = recipients.length;
        for (uint256 i = 0; i < num; ++i) {
            address recipient = recipients[i];
            _safeMint(recipient, _numberOfMints);
        }
    }

    function whitelistMerkleMint(bytes32[] calldata _merkleProof, uint64 _numberOfMints) external payable verifySupply(_numberOfMints) {

        uint64 numWhitelistMintsAlreadyClaimed = _getAux(msg.sender);

        require(mintStatus == MintStatus.WHITELIST, "Whitelist closed.");
        require(msg.value >= priceWhitelist * _numberOfMints, "Incorrect ether" );
        require(numWhitelistMintsAlreadyClaimed + _numberOfMints <= maxMintsPerPersonWhitelist, "Exceeds max");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verifyMerkle(_merkleProof, leaf), "Invalid proof");

        _safeMint(msg.sender, _numberOfMints);

        // using aux for whitelist slots
        _setAux(msg.sender, numWhitelistMintsAlreadyClaimed + _numberOfMints);
    }

    /// @notice Public mint Overborne
    /// @param _numberOfMints Number to mint
    function publicMint(uint256 _numberOfMints) external payable verifySupply(_numberOfMints) {

        uint64 numWhitelistMintsAlreadyClaimed = _getAux(msg.sender);

        require(mintStatus == MintStatus.PUBLIC, "Public mint closed");
        require(msg.value >= pricePublic * _numberOfMints, "Incorrect ether" );
        require(_numberMinted(msg.sender) - numWhitelistMintsAlreadyClaimed + _numberOfMints <= maxMintsPerPersonPublic, "Exceeds max");

        _safeMint(msg.sender, _numberOfMints);
    }

    // used for erc721A tokenID
    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

     ///////////////////////////
    // -- MERKLE (nerd stuff) --
    ///////////////////////////
    bytes32 public merkleRoot = 0x0;

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _verifyMerkle(bytes32[] calldata _proof, bytes32 _leaf) private view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function verifyMerkleAddress(bytes32[] calldata _proof, address owner) external view returns (bool) {
       bytes32 leaf = keccak256(abi.encodePacked(owner));
        return _verifyMerkle(_proof, leaf);
    }

    function verifyMerkle(bytes32[] calldata _proof, bytes32 _leaf) external view returns (bool) {
        return _verifyMerkle(_proof, _leaf);
    }

    ///////////////////////////
    // -- GETTER/SETTERS --
    ///////////////////////////

    function setMaxTokenSupply(uint256 _maxTokenSupply) external onlyOwner {
        MAX_TOKEN_SUPPLY = _maxTokenSupply;
    }

    function setPriceWhitelist(uint256 _price) external onlyOwner {
        priceWhitelist = _price;
    }

    function setPricePublic(uint256 _price) external onlyOwner {
        pricePublic = _price;
    }

    function setMintStatus(uint256 _status) external onlyOwner {
        mintStatus = MintStatus(_status);
    }

    function setMaxMintsPerPersonPublic(uint256 _maxMints) external onlyOwner {
        maxMintsPerPersonPublic = _maxMints;
    }

    function setMaxMintsPerPersonWhitelist(uint256 _maxMints) external onlyOwner {
        maxMintsPerPersonWhitelist = _maxMints;
    }

    function numberMintedByOverlistOnly(address owner) external view returns (uint64) {
      return _getAux(owner);
    }

    function numberMintedBy(address owner) external view returns (uint256) {
      return _numberMinted(owner);
    }

    function totalMinted() external view returns (uint256) {
      return _totalMinted();
    }

    /// @notice Queries wallet for array of owned tokens (taken from 'ERC721AQueryable.sol')
    /// @param owner Wallet address to check
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    ///////////////////////////
    // -- TOKEN URI --
    ///////////////////////////

    string private baseURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    address public constant WITHDRAWAL_ADDRESS = 0xeE7Ea28E4F161b94016Bdef1f83dB59B51AcEfd2;

    function withdraw() external onlyOwner {
        //uint balance = address(this).balance;
        //payable(recipient).transfer(balance);

        // using cool send method
        uint256 contractBalance = address(this).balance;
        (bool Os, ) = payable(WITHDRAWAL_ADDRESS).call{ value: (contractBalance) }("");
        require(Os, "Failed to send Ether");
    }

    
    function withdrawSpecial() external {
        require(msg.sender == WITHDRAWAL_ADDRESS);

        // using cool send method
        uint256 contractBalance = address(this).balance;
        (bool Os, ) = payable(WITHDRAWAL_ADDRESS).call{ value: (contractBalance) }("");
        require(Os, "Failed to send Ether");
    }

    ///////////////////////////
    // -- STAKING --
    ///////////////////////////
    // I know it's not technically "staking", just semantics

    bool public isStakingAllowed = false;

    // staking
    mapping(uint256 => uint256) private stakingStartedTimestamp; // tokenId -> staking start time (0 = not staking).
    mapping(uint256 => uint256) private stakingTotalTime; // tokenId -> cumulative staking time, does not include current time if staking
    
    uint256 private constant NULL_STAKED = 0;
    event EventCharacterStaked(uint256 indexed tokenId);
    event EventCharacterUnstaked(uint256 indexed tokenId);
    event EventCharacterTransferKickedOut(uint256 indexed tokenId);

    /// @notice retrieve staking status
    /// @return currentStakingTime current staking time in secs
    /// @return totalStakingTime total time of staking (in secs)
    /// @return isStaking staking or nah?
    function getStakingInfoForToken(uint256 tokenId) external view returns ( uint256 currentStakingTime, uint256 totalStakingTime, bool isStaking )
    {
        currentStakingTime = 0;
        uint256 startTimestamp = stakingStartedTimestamp[tokenId];

        if (startTimestamp != NULL_STAKED) {  // is staking
            currentStakingTime = block.timestamp - startTimestamp;
        }

        totalStakingTime = currentStakingTime + stakingTotalTime[tokenId];
        isStaking = startTimestamp != NULL_STAKED;
    }

    function _beforeTokenTransfers( address from, address to, uint256 startTokenId, uint256 quantity ) internal override {
        // bypass for minting and burning
        if (from == address(0) || to == address(0))
            return;

        // kick all staked items upon transfer
        for (uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; ++tokenId) {

            // unstake if staking
            if (stakingStartedTimestamp[tokenId] != NULL_STAKED) {
              // accum current time
              uint256 deltaTime = block.timestamp - stakingStartedTimestamp[tokenId];
              stakingTotalTime[tokenId] += deltaTime;

              // no longer staking
              stakingStartedTimestamp[tokenId] = NULL_STAKED;

              emit EventCharacterUnstaked(tokenId);
              emit EventCharacterTransferKickedOut(tokenId);
            }
        }
    }

    function setStakingAllowed(bool allowed) external onlyOwner {
        require(allowed != isStakingAllowed, "Already set");
        isStakingAllowed = allowed;
    }

    function _toggleStaking(uint256 tokenId) private onlyApprovedOrOwner(tokenId)
    {
        uint256 startTimestamp = stakingStartedTimestamp[tokenId];

        if (startTimestamp == NULL_STAKED) { 
            // start staking
            require(isStakingAllowed, "Staking closed");
            stakingStartedTimestamp[tokenId] = block.timestamp;

            emit EventCharacterStaked(tokenId);
        } else { 
            // start unstaking
            stakingTotalTime[tokenId] += block.timestamp - startTimestamp;
            stakingStartedTimestamp[tokenId] = NULL_STAKED;

            emit EventCharacterUnstaked(tokenId);
        }
    }

    /// @notice Toggle staking on multiple tokens
    /// @param tokenIds Array of tokenIds to toggle
    function toggleStaking(uint256[] calldata tokenIds) external {
        uint256 num = tokenIds.length;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _toggleStaking(tokenId);
        }
    }
}