// SPDX-License-Identifier: MIT

/*
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  CRYPTO EDDIES  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX   by @eddietree  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  (LET TRY THIS AGAIN SHALL WE?) XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWx'....................................:0WWWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNo.                                    ,ONNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNWWNd'..;looooooooooooooooooooooooooooooooooooc,..;OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNNWNl   ,xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo.  .kWNNNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWNd,',:llldkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxollc;'';OWWWNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd.  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ,kOOOOOOOOOOO0000000KKKKKKKKKKKKKKKKK00000000Kx.  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOOOOOOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOO000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKOl;;ckKKKKKKKKKKKKKKKKkc;;lOXXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKk'  .oKKKKKKKKKKKKKKKXo.  .xXXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNNNXxllc.   ;kOOOOOO0KKKKKKK0occc::::cxKKKKKKKkc:::cccoOKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXNWMMX;       ;kOOOOOO0KKKKKKKKKKXO,    cKKKKKKKl   'OXXXKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXNNNKxoolc:::::::okOOOOOO0KKKKKKK0occc:::::xKKKKKKKxc:::cccoOKXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKK0OOOOOOO0KKKKKKXk'  .oKKKKKKKKKKKKKKXKo.  .xKXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKKK000OOOO0KKKKKKKOl;;:kKKKKKKKKK0000KKKkc;;lOKKOl;;:lddd0NNNXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKKKKKK0OOO0KKKKKKKKKKKKKKKKKKKKK0kkkOKKKKKKKKKKKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXNWWKo;;:coooooookKKKK0000KKKKKKKKKKK0xooookKKKxc::d0KKOdood0KKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXNWWMX;       :0KKKKKKKKKKKKKKKKKXO,    cKKKc   ;0KXo.  .xKKKKKXO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNWWXo,,,,,,,coodkKKKKKKKKKKKKKKK0c''',codo:''':oddc,'':kXKKKKXO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWWWWWNl   ;0KKKKKKKKKKKKKKKKKKKO;   :0K0l.  ,kKKKKKKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWWWWWNx,'':dddkKKKKKKKKKKKKKKKX0l..'oKKKd'..:OXKKKKK0kddo:'',xWWWNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNd.  ,OXKKKKKKKKKKKKKKKK000KKKKK0000KKKKKKKk,  .dNNNNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXNXK000o'..;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo;..,kWWWNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNWMWo...;k0Ol.                                    'xXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXKK0l...c0KKd'............................     ...,OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWNl...:kOO0KKX0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOc.  .xKKXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXX0c...cKKK0OOO0KKKKKKKKKKKKKKKKKKKKKKKKK0OOOl.  '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNWWXc..'cxkk0KKKo...:OKKKKKKKOkkO0KKKK0kkO0KKKo'...   '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;   lKKKKKKKl.  ,x000KKKKOkkk0KKKKOkkk0KKKl       ,ONNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;   cKKKKKKK0xxxl'..;kXKKK000KKKKKK000KKKKl   .oxxo,'.:OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;  .c000KKKKKKKKo.  .xKKKKKKKKKKKKKKKKKKKKl   'kXXx.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXNNX0kkkc'''oKKKKKKKo.  .xKK0dlloxkkkkkkkk0KKKl   'kXXx.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMNc   :0KKKKKKo.  .xKKOl:::oxxxxxxxxOKKKl   'kKKd.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNNNX0xxxc,,,,,,,;loox0KKOl:::oxxxxxxxxOKKKl    ',,:oxxkKNNNXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNMMWl       'kXKKKKKOl;::oxxxxxxxxOKKKl       '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNNNN0ddd;   'OXXkc,,;;:::oxxxxxxxxOKKKl   .lddkKNNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OXXd.   ':::oxxxxxxxxOKKKl   ,KMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OKXx.  .lOOO0KKK0o,,,oKKKl   ,KMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OKKd.  .kMMMMMMMNc   :0XKl   ,KMMWXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWx'..:OXXk;..;OWWWWWWWNo...lKKKd'..cKWWNXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
*/
// special thanks to 0xmetazen and troph for reviewing the code

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import "./EddieRenderer.sol";
import "./CryptoDeddiesV2.sol";
import "./CryptoEddies.sol"; // OG

/// @title CryptoEddies V2
/// @author @eddietree
/// @notice CryptoEddies is an 100% on-chain experimental NFT character project.
contract CryptoEddiesV2 is ERC721A, Ownable {
    
    uint256 public constant MAX_TOKEN_SUPPLY = 3500;
    uint public constant MAX_HP = 5;

    // contracts
    CryptoDeddiesV2 public contractGhost;
    CryptoEddies public contractEddieOG;
    address public contractHpEffector;

    bool public revealed = true;
    bool public rerollingEnabled = true;
    bool public claimEnabled = true;
    bool public burnSacrificeEnabled = false;

    mapping(uint256 => uint256) public ogTokenId; // tokenId=>ogTokenId (From original contract)
    mapping(uint256 => uint256) public seeds; // seeds for image + stats
    mapping(uint256 => uint) public hp; // health power

    // events
    event EddieDied(uint256 indexed tokenId); // emitted when an HP goes to zero
    event EddieRerolled(uint256 indexed tokenId); // emitted when an Eddie gets re-rolled
    event EddieSacrificed(uint256 indexed tokenId); // emitted when an Eddie gets sacrificed

    constructor(address _contractEddieOG) ERC721A("CryptoEddiesV2", "EDDIEV2") {
        contractEddieOG = CryptoEddies(_contractEddieOG);
    }

    modifier verifyTokenId(uint256 tokenId) {
        require(tokenId >= _startTokenId() && tokenId <= _totalMinted(), "Out of bounds");
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

    function claimMany(uint256[] calldata tokenIds) external {
        require(claimEnabled == true);

        // clamp the total minted
        //require(_totalMinted() + tokenIds.length <= MAX_TOKEN_SUPPLY );

        uint256 num = tokenIds.length;
        uint256 startTokenId = _startTokenId() + _totalMinted();
        address sender = msg.sender;

        for (uint256 i = 0; i < num; ++i) {
            uint256 originalTokenId = tokenIds[i];
            uint256 newTokenId = startTokenId + i;

            //require(sender == contractEddieOG.ownerOf(originalTokenId)); // check ownership
            //require(ogTokenId[newTokenId] == 0); // check not already claimed

            // transfer each token to this contract and then call the burn function
            // since the 'burnSacrifice' call can only be called on the owner,
            // we had to first transfer to this contract before excuting burnSacrifice
            contractEddieOG.transferFrom(sender, address(this), originalTokenId);
            contractEddieOG.burnSacrifice(originalTokenId);

            // save data on new token
            ogTokenId[newTokenId] = originalTokenId;
            hp[newTokenId] = MAX_HP;
            _saveSeed(newTokenId); // reshuffle
            //seeds[newTokenId] = contractEddieOG.seeds(originalTokenId); // copy seed over
        }

        //_safeMint(sender, num);
        _mint(sender, num);
    }

    function _rerollEddie(uint256 tokenId) verifyTokenId(tokenId) private {
        require(revealed == true, "Not revealed");
        require(hp[tokenId] > 0, "No HP");
        require(msg.sender == ownerOf(tokenId), "Not yours");

        _saveSeed(tokenId);   
        _takeDamageHP(tokenId, msg.sender);

        emit EddieRerolled(tokenId);
    }

    /// @notice Rerolls the visuals and stats of one CryptoEddie, deals -1 HP damage!
    /// @param tokenId The token ID for the CryptoEddie to reroll
    function rerollEddie(uint256 tokenId) external {
        require(rerollingEnabled == true);
        _rerollEddie(tokenId);
    }

    /// @notice Rerolls the visuals and stats of many CryptoEddies, deals -1 HP damage!
    /// @param tokenIds An array of token IDs
    function rerollEddieMany(uint256[] calldata tokenIds) external {
        require(rerollingEnabled == true);
        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _rerollEddie(tokenId);
        }
    }

    function _saveSeed(uint256 tokenId) private {
        seeds[tokenId] = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, msg.sender)));
    }

    /// @notice Destroys your CryptoEddie, spawning a ghost
    /// @param tokenId The token ID for the CryptoEddie
    function burnSacrifice(uint256 tokenId) external onlyApprovedOrOwner(tokenId) {
        //require(msg.sender == ownerOf(tokenId), "Not yours");
        require(burnSacrificeEnabled == true);

        address ownerOfEddie = ownerOf(tokenId);

        _burn(tokenId);

        // if not already dead, force kill and spawn ghost
        if (hp[tokenId] > 0) {
            hp[tokenId] = 0;
        
             // cancel vibing
            _resetAndCancelVibing(tokenId);

            emit EddieDied(tokenId);

            if (address(contractGhost) != address(0)) {
                contractGhost.spawnGhost(ownerOfEddie, tokenId, seeds[tokenId]);
            }
        }

        emit EddieSacrificed(tokenId);
    }

    function _startTokenId() override internal pure virtual returns (uint256) {
        return 1;
    }

    // taken from 'ERC721AQueryable.sol'
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

    function setContractEddieOG(address newAddress) external onlyOwner {
        contractEddieOG = CryptoEddies(newAddress);
    }

    function setContractGhost(address newAddress) external onlyOwner {
        contractGhost = CryptoDeddiesV2(newAddress);
    }

    function setClaimEnabled(bool _enabled) external onlyOwner {
        claimEnabled = _enabled;
    }

    function setContractHpEffector(address newAddress) external onlyOwner {
        contractHpEffector = newAddress;
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setRerollingEnabled(bool _enabled) external onlyOwner {
        rerollingEnabled = _enabled;
    }

    function setBurnSacrificeEnabled(bool _enabled) external onlyOwner {
        burnSacrificeEnabled = _enabled;
    }

    // props to @cygaar_dev
    //error SteveAokiNotAllowed();
    //address public constant STEVE_AOKI_ADDRESS = 0xe4bBCbFf51e61D0D95FcC5016609aC8354B177C4;

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
        // removed to optimize gas, u are now re-admitted into the club, Mr. Aoki
        /*if (to == STEVE_AOKI_ADDRESS) { // sorry Mr. Aoki
            revert SteveAokiNotAllowed();
        }*/

        if (from == address(0) || to == address(0))  // bypass for minting and burning
            return;

        for (uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; ++tokenId) {
            //require(hp[tokenId] > 0, "No more HP"); // soulbound?

            // transfers reduces HP
            _takeDamageHP(tokenId, from);
        }
    }

    function _takeDamageHP(uint256 tokenId, address mintGhostTo) private verifyTokenId(tokenId){
        if (hp[tokenId] == 0) // to make sure it doesn't wrap around
            return;

        hp[tokenId] -= 1;

        // taking damage resets your vibing
        _resetAndCancelVibing(tokenId);

        if (hp[tokenId] == 0) {
            emit EddieDied(tokenId);

            if (address(contractGhost) != address(0)) {
                contractGhost.spawnGhost(mintGhostTo, tokenId, seeds[tokenId]);
            }
        }
    }

    function rewardManyHP(uint256[] calldata tokenIds, int hpRewarded) external /*onlyOwner*/ {
        // only admin or another authorized smart contract can change HP
        // perhaps a hook for future content? ;)
        require(owner() == _msgSender() || (contractHpEffector != address(0) && _msgSender() == contractHpEffector), "Not authorized");

        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];

            if (hp[tokenId] > 0 ) { // not dead

                int newHp = int256(hp[tokenId]) + hpRewarded;

                // clamping between [0,MAX_HP]
                if (newHp > int(MAX_HP)) 
                    newHp = int(MAX_HP);
                
                else if (newHp <= 0) {
                    newHp = 0;

                    // spawn ghost
                    emit EddieDied(tokenId);
                    if (address(contractGhost) != address(0)) {
                        contractGhost.spawnGhost(ownerOf(tokenId), tokenId, seeds[tokenId]);
                    }
                }

                hp[tokenId] = uint256(newHp);

                // taking damage resets your vibing
                if (hpRewarded < 0) {
                     _resetAndCancelVibing(tokenId);
                }
            }
        }
    }

    /// @notice Retrieves the HP
    /// @param tokenId The token ID for the CryptoEddie
    /// @return hp the amount of HP for the CryptoEddie
    function getHP(uint256 tokenId) external view verifyTokenId(tokenId) returns(uint){
        return hp[tokenId];
    }

    function numberMinted(address addr) external view returns(uint256){
        return _numberMinted(addr);
    }

    ///////////////////////////
    // -- TOKEN URI --
    ///////////////////////////
    function _tokenURI(uint256 tokenId) private view returns (string memory) {
        string[6] memory lookup = [  '0', '1', '2', '3', '4', '5'];
        uint256 seed = seeds[tokenId];
        string memory image = contractEddieOG.getSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"CryptoEddie #', Strings.toString(tokenId),'",',
                    '"description": "CryptoEddies is an 100% on-chain experimental NFT character project with unique functionality, inspired by retro Japanese RPGs. Formerly known as CryptoEddie #', Strings.toString(ogTokenId[tokenId]),'.",',
                    '"attributes":[',
                        contractEddieOG.getTraitsMetadata(seed),
                        _getStatsMetadata(seed),
                        '{"trait_type":"Vibing?", "value":', (vibingStartTimestamp[tokenId] != NULL_VIBING) ? '"Yes"' : '"Nah"', '},',
                        //'{"trait_type":"OG TokenID", "value":', Strings.toString(ogTokenId[tokenId]), '},',
                        '{"trait_type":"HP", "value":',lookup[hp[tokenId]],', "max_value":',lookup[MAX_HP],'}'
                    '],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _tokenUnrevealedURI(uint256 tokenId) private view returns (string memory) {
        uint256 seed = seeds[tokenId];
        string memory image = contractEddieOG.getUnrevealedSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"CryptoEddie #', Strings.toString(tokenId),'",',
                    '"description": "CryptoEddies is an 100% on-chain experimental character art project, chillin on the Ethereum blockchain.",',
                    '"attributes":[{"trait_type":"Unrevealed", "value":"True"}],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function tokenURI(uint256 tokenId) override(ERC721A) public view verifyTokenId(tokenId) returns (string memory) {
        if (revealed) 
            return _tokenURI(tokenId);
        else
            return _tokenUnrevealedURI(tokenId);
    }

    function _randStat(uint256 seed, uint256 div, uint256 min, uint256 max) private pure returns (uint256) {
        return min + (seed/div) % (max-min);
    }

    function _getStatsMetadata(uint256 seed) private pure returns (string memory) {
        string[11] memory lookup = [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' ];

        string memory metadata = string(abi.encodePacked(
          '{"trait_type":"Determination", "display_type": "number", "value":', lookup[_randStat(seed, 2, 2, 10)], '},',
          '{"trait_type":"Love", "display_type": "number", "value":', lookup[_randStat(seed, 3, 2, 10)], '},',
          '{"trait_type":"Cringe", "display_type": "number", "value":', lookup[_randStat(seed, 4, 2, 10)], '},',
          '{"trait_type":"Bonk", "display_type": "number", "value":', lookup[_randStat(seed, 5, 2, 10)], '},',
          '{"trait_type":"Magic Defense", "display_type": "number", "value":', lookup[_randStat(seed, 6, 2, 10)], '},'
        ));

        return metadata;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    ///////////////////////////
    // -- VIBING --
    ///////////////////////////

    bool public isVibingEnabled = false;

    // vibing
    mapping(uint256 => uint256) private vibingStartTimestamp; // tokenId -> vibing start time (0 = not vibing).
    mapping(uint256 => uint256) private vibingTotalTime; // tokenId -> cumulative vibing time, does not include current time if vibing
    
    uint256 private constant NULL_VIBING = 0;
    event EventStartVibing(uint256 indexed tokenId);
    event EventEndVibing(uint256 indexed tokenId);
    event EventForceEndVibing(uint256 indexed tokenId);

    // currentVibingTime: current vibing time in secs (0 = not vibing)
    // totalVibingTime: total time of vibing (in secs)
    function getVibingInfoForToken(uint256 tokenId) external view returns (uint256 currentVibingTime, uint256 totalVibingTime)
    {
        currentVibingTime = 0;
        uint256 startTimestamp = vibingStartTimestamp[tokenId];

        // is vibing?
        if (startTimestamp != NULL_VIBING) { 
            currentVibingTime = block.timestamp - startTimestamp;
        }

        totalVibingTime = currentVibingTime + vibingTotalTime[tokenId];
    }

    function setVibingEnabled(bool allowed) external onlyOwner {
        require(allowed != isVibingEnabled);
        isVibingEnabled = allowed;
    }

    function _toggleVibing(uint256 tokenId) private onlyApprovedOrOwner(tokenId)
    {
        require(hp[tokenId] > 0);

        uint256 startTimestamp = vibingStartTimestamp[tokenId];

        if (startTimestamp == NULL_VIBING) { 
            // start vibing
            require(isVibingEnabled, "Disabled");
            vibingStartTimestamp[tokenId] = block.timestamp;

            emit EventStartVibing(tokenId);
        } else { 
            // start unvibing
            vibingTotalTime[tokenId] += block.timestamp - startTimestamp;
            vibingStartTimestamp[tokenId] = NULL_VIBING;

            emit EventEndVibing(tokenId);
        }
    }

    function toggleVibing(uint256[] calldata tokenIds) external {
        uint256 num = tokenIds.length;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _toggleVibing(tokenId);
        }
    }

    function _resetAndCancelVibing(uint256 tokenId) private {
        if (vibingStartTimestamp[tokenId] != NULL_VIBING) {
            vibingStartTimestamp[tokenId] = NULL_VIBING;
            emit EventEndVibing(tokenId);
        }

        // clear total time
        if (vibingTotalTime[tokenId] != NULL_VIBING)    
            vibingTotalTime[tokenId] = NULL_VIBING;
    }

    function _adminForceStopVibing(uint256 tokenId) private {
        require(vibingStartTimestamp[tokenId] != NULL_VIBING, "Character not vibing");
        
        // accum current time
        uint256 deltaTime = block.timestamp - vibingStartTimestamp[tokenId];
        vibingTotalTime[tokenId] += deltaTime;

        // no longer vibing
        vibingStartTimestamp[tokenId] = NULL_VIBING;

        emit EventEndVibing(tokenId);
        emit EventForceEndVibing(tokenId);
    }

    function adminForceStopVibing(uint256[] calldata tokenIds) external onlyOwner {
        uint256 num = tokenIds.length;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _adminForceStopVibing(tokenId);
        }
    }
}