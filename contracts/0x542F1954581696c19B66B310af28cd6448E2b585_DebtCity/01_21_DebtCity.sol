// contracts/DebtCity.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./IPaper.sol";
import "./DebtCityLibrary.sol";



contract DebtCity is ERC721Enumerable, Ownable, RoyaltiesV2Impl {


/*



██████╗░███████╗██████╗░████████╗░█████╗░██╗████████╗██╗░░░██╗
██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██║╚══██╔══╝╚██╗░██╔╝
██║░░██║█████╗░░██████╦╝░░░██║░░░██║░░╚═╝██║░░░██║░░░░╚████╔╝░
██║░░██║██╔══╝░░██╔══██╗░░░██║░░░██║░░██╗██║░░░██║░░░░░╚██╔╝░░
██████╔╝███████╗██████╦╝░░░██║░░░╚█████╔╝██║░░░██║░░░░░░██║░░░
╚═════╝░╚══════╝╚═════╝░░░░╚═╝░░░░╚════╝░╚═╝░░░╚═╝░░░░░░╚═╝░░░    



*/


    using DebtCityLibrary for uint8;

    mapping(string => bool) hashToMinted;
    mapping(uint256 => string) internal bankerIdToHash;

    uint256 MAX_SUPPLY = 4999;
    uint256 SEED_NONCE = 0;

    uint256 REMAINING_BOARD_MEMBERS = 25;
    uint256 REMAINING_DIRECTORS = 200;
    uint256 REMAINING_VPS = 800;
    uint256 REMAINING_ASSOCIATES = 1500;
    uint256 REMAINING_ANALYSTS = 2474;

    mapping(address => uint8) private _allowList;
    bool isAllowListActive = true;
    bool isMintActive = false;
    address payable public payableWallet;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    uint256 public ethPrice = 0.079 ether;
    uint8 maxPerWallet = 2;

    struct PngTrait {
        string ttype;
        string name;
        string png;
        bool on;
    }

    mapping(uint8 => mapping(uint8 => PngTrait)) public traitData;
    uint16[][15] TIERS;

    string[] LETTERS = [
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
        "m",
        "n",
        "o",
        "p",
        "q",
        "r",
        "s",
        "t",
        "u",
        "v",
        "w",
        "x",
        "y",
        "z"
    ];

    address paperAddress;
    address _owner;

    constructor() ERC721("DebtCity", "BANKERS") {
        _owner = msg.sender;
        payableWallet = payable(address(0xBC590a5370cc163023cdC17e041967796174081B));

        // 9 skin vals
        TIERS[0] = [20, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1100];
        // 9 eye vals
        TIERS[1] = [1120, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110];
        // 4 mouth vals
        TIERS[2] = [2500, 2500, 2500, 2500];
        // 4 shoes vals
        TIERS[3] = [2500, 2500, 2500, 2500];
        // 4 pants vals
        TIERS[4] = [2500, 2500, 2500, 2500];
        // 8 dress shirt vals
        TIERS[5] = [1250, 1250, 1250, 1250, 1250, 1250, 1250, 1250];
        // 4 glasses vals
        TIERS[6] = [2500, 2500, 2500, 2500];
        // 10 t-shirt vals
        TIERS[7] = [1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000];
        // 10 polo vals
        TIERS[8] = [1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000];
        // 6 tie vals
        TIERS[9] = [1675, 1665, 1665, 1665, 1665, 1665];
        // 7 vest vals
        TIERS[10] = [1432, 1428, 1428, 1428, 1428, 1428, 1428];
        // 5 jacket vals
        TIERS[11] = [2000, 2000, 2000, 2000, 2000];
        // 6 pock square vals
        TIERS[12] = [1675, 1665, 1665, 1665, 1665, 1665];
        // 9 hair vals
        TIERS[13] = [1120, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110];
        // 5 watch vals
        TIERS[14] = [2500, 2500, 2500, 1250, 1250];
    }



    /** *********************************** **/
    /** ********* Minting Functions ******* **/
    /** *********************************** **/


    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        view
        returns (uint8)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    
    function hash(
        uint256 _t,
        address _a,
        uint256 _c
    ) internal returns (string memory) {
        require(_c < 10);

        // This will generate a 16 character string
        // The last 15 digits are random, the first is 1-5 depending on the random
        // banker style assigned to the token

        string memory currentHash = "";
        SEED_NONCE++; 

        uint16 randValue = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        _t,
                        _a,
                        _c,
                        SEED_NONCE
                    )
                )
            ) 
        );

        uint8 bstyle = getBankerStyle(randValue); // get a random banker style
        currentHash = string(abi.encodePacked(currentHash, bstyle.toString()));

        uint8 pindex = 0;
        bool willForceNoPolo = false;

        for (uint8 i = 0; i < 15; i++) {
            SEED_NONCE++;
            uint16 _randinput = uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            SEED_NONCE
                        )
                    )
                ) % 10000
            );

            uint8 randDigit = rarityGen(_randinput, i);
            uint8 traitVal = applyBankerRules(i, bstyle, randDigit, _randinput);


            if (bstyle == 1 && i == 4) pindex = traitVal; // keep track of pants colors for members
            else if (bstyle == 1 && i == 12) traitVal = pindex + 1;

            if (i == 7 && traitVal != 0) willForceNoPolo = true;
            if (i == 8 && willForceNoPolo) traitVal = 0;

            currentHash = string(
                abi.encodePacked(currentHash, traitVal.toString())
            );
        } 

        if (hashToMinted[currentHash]) return hash(_t, _a, _c + 1);

        return currentHash;
    }


    function mintInternal(uint8 quantity) internal {

        uint256 _totalSupply = totalSupply();
        require(_totalSupply + quantity < MAX_SUPPLY);
        require(!DebtCityLibrary.isContract(msg.sender));
        require(msg.value == (ethPrice * quantity));
        require(
            balanceOf(msg.sender) + quantity <= maxPerWallet,
            "exceeds max per wallet"
        );

        uint8 i = 0;
        uint256 newBankerId = _totalSupply;
        while (i < quantity) {
            uint256 bankerId = newBankerId + i;
            bankerIdToHash[bankerId] = hash(bankerId, msg.sender, 0);
            hashToMinted[bankerIdToHash[bankerId]] = true;
            _safeMint(msg.sender, bankerId);
            i ++;
        }
    }

    function mintBanker(uint8 quantity) external payable {
        require(isAllowListActive == false, "Only the allow list can mint right now");
        return mintInternal(quantity);
    }


    function mintAllowList(uint8 quantity) external payable {

        require(isAllowListActive, "Allow list is not active");
        require(quantity <= _allowList[msg.sender], "Exceeded max available to purchase");

        _allowList[msg.sender] -= quantity;
        mintInternal(quantity);
     }


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // hardcode approval so that users don't have to waste gas approving
        if (_msgSender() != address(paperAddress)){
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        }
        _transfer(from, to, tokenId);
    }


    


    /** *********************************** **/
    /** ******* Internal Functions ******** **/
    /** *********************************** **/


    function applyBankerRules(uint8 i, uint8 bstyle, uint8 randDigit, uint16 bigRandom) pure internal returns (uint8) {

        if (i == 6 && bigRandom % 2 == 0) randDigit = 0;
        else if (i == 7 || i == 8) {
            if ((bstyle == 5 && bigRandom % 2 == 0) || bstyle < 5) randDigit = 0;
        } 
        else if (i == 9) {
            if (bstyle  == 5 || bstyle == 4 || (bstyle == 2 && bigRandom % 2 == 0)) randDigit = 0;
            if (bstyle == 3 && randDigit == 0) randDigit = 1;
        }
        else if (i == 10) {
            if (bstyle < 4 || bigRandom % 2 == 0) randDigit = 0;
        }
        else if (i == 11) {
            if (bstyle > 2) randDigit = 0;
        }
        else if (i == 12 && bstyle > 1) randDigit = 0;
        else if (i == 13 && bigRandom % 3 == 0) randDigit = 0;
        else if(i == 14 && (bigRandom % 2 == 0 || bstyle == 5)) randDigit = 0; 


        return randDigit;

    }
    



    function getBankerStyle(uint16 rando) internal returns (uint8) {     

        uint16 randVal = (rando & 0xFFFF);

        if (REMAINING_BOARD_MEMBERS > 0 && randVal % 200 == 0) { // ~0.5 % chance
            REMAINING_BOARD_MEMBERS--;
            return 1;
        }

        if (REMAINING_DIRECTORS > 0 && randVal % 25 == 0) { // ~4 % chance
            REMAINING_DIRECTORS--;
            return 2;
        }

        if (REMAINING_VPS > 0 && randVal % 6 == 0) { // ~16 % chance
            REMAINING_VPS--;
            return 3;
        }

        if (REMAINING_ASSOCIATES > 0 && randVal % 3 == 0) { // ~30 % chance
            REMAINING_ASSOCIATES--;
            return 4;
        } 

        if (REMAINING_ANALYSTS > 0) { // assign analyst if available
            REMAINING_ANALYSTS--;
            return 5;
        } 


        // else find the lowest ranking available banker type 
        uint8 res = getLowestType();
        return res;

    }


    function getLowestType() internal returns (uint8) {
        if (REMAINING_ANALYSTS > 0) {
            REMAINING_ANALYSTS--;
            return 5;
        }

        if (REMAINING_ASSOCIATES > 0) {
            REMAINING_ASSOCIATES--;
            return 4;
        }

        if (REMAINING_VPS > 0) {
            REMAINING_VPS--;
            return 3;
        }

        if (REMAINING_DIRECTORS > 0) {
            REMAINING_DIRECTORS--;
            return 2;
        }

        if (REMAINING_BOARD_MEMBERS > 0) {
            REMAINING_BOARD_MEMBERS--;
            return 1;
        }

        return 0;
    }  

    function getJobString(uint8 job) internal pure returns (string memory) {
        if (job == 5) return "analyst";
        else if (job == 4) return "associate";
        else if (job == 3) return "vice_president";
        else if (job == 2) return "director";
        else if (job == 1) return "board_member";
        return "none";
    }   




    /** *********************************** **/
    /** ********* Public Getters ********** **/
    /** *********************************** **/
    
    function getBankersRemaining() public view returns (uint256) {
        return (REMAINING_BOARD_MEMBERS + REMAINING_DIRECTORS + REMAINING_VPS + REMAINING_ASSOCIATES + REMAINING_ANALYSTS); 
    }


    function hashToMetadata(string memory _hash)
        public
        view
        returns (string memory)
    {
        uint8 job = DebtCityLibrary.parseInt(
            DebtCityLibrary.substring(_hash, 0, 1)
        );

        string memory metadataString = string(
            abi.encodePacked(
                '{"trait_type":"job_title","value":"',
                getJobString(job), '"},'
            )
        );

        for (uint8 i = 0; i < 15; i++) {
            uint8 hashIndex = i + 1;
            uint8 thisTraitIndex = DebtCityLibrary.parseInt(
                DebtCityLibrary.substring(_hash, hashIndex, hashIndex + 1)
            );

            PngTrait memory t = traitData[i][thisTraitIndex];

            if (t.on) {

                if (i != 0) metadataString = string(abi.encodePacked(metadataString, ","));

                metadataString = string(
                    abi.encodePacked(
                        metadataString,
                        '{"trait_type":"',
                        t.ttype,
                        '","value":"',
                        t.name,
                        '"}'
                    )
                );
            }
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }


    function tokenURI(uint256 _bankerId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_bankerId));

        string memory bankerHash = _bankerIdToHash(_bankerId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    DebtCityLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "DebtCity #',
                                    DebtCityLibrary.toString(_bankerId),
                                    '", "description": "DebtCity is the first on-chain economic simulator. No IPFS, no API. Just an Ethereum blockchain simulation of finance, investment, and degeneracy", "image": "data:image/svg+xml;base64,',
                                    DebtCityLibrary.encode(
                                        bytes(outputFullSVG(bankerHash))
                                    ),
                                    '","attributes":',
                                    hashToMetadata(bankerHash),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }


    function _bankerIdToHash(uint256 _bankerId)
        public
        view
        returns (string memory)
    {
        return bankerIdToHash[_bankerId];
    }


    function getPayForBanker(uint256 _bankerId)
        public
        view
        returns (uint8)
    {
        string memory bankerHash = bankerIdToHash[_bankerId];

        uint8 jobVal = DebtCityLibrary.parseInt(
            DebtCityLibrary.substring(bankerHash, 0, 1)
        );

        if (jobVal == 1) return 15;
        if (jobVal == 2) return 8;
        if (jobVal == 3) return 3;
        if (jobVal == 4) return 2;

        return 1;
    }


    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 bankerCount = balanceOf(_wallet);

        uint256[] memory bankersId = new uint256[](bankerCount);
        for (uint256 i; i < bankerCount; i++) {
            bankersId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return bankersId;
    }




    /** *********************************** **/
    /** ********* Owner Functions ********* **/
    /** *********************************** **/

    function clearTraits() public onlyOwner {
        for (uint8 i = 0; i < 15; i++) {
            for (uint8 j = 0; j < 15; j++) { 
                delete traitData[i][i];
            }
        }
    }
    

    function outputFullSVG(string memory _hash) public view returns (string memory) {
       
        string memory svgString = "";

        for (uint8 i = 0; i < 15; i++) {

            uint8 hashIndex = i + 1;
            uint8 thisTraitIndex = DebtCityLibrary.parseInt(
                DebtCityLibrary.substring(_hash, hashIndex, hashIndex + 1)
            );

            PngTrait memory t = traitData[i][thisTraitIndex];
            if (t.on) svgString = string(abi.encodePacked(svgString, drawTrait(t)));
        }

        return string(abi.encodePacked(
          '<svg id="banker" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          svgString,
          "</svg>"
        ));
    }


    function drawTrait(PngTrait memory trait) internal pure returns (string memory) {
        return string(abi.encodePacked(
          '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
          trait.png,
          '"/>'
        ));
    }


    function uploadTraits(uint8 traitType, PngTrait[] memory traits) public onlyOwner {
        for (uint8 i = 0; i < traits.length; i++) {
            traitData[traitType][i] = PngTrait(
                traits[i].ttype,
                traits[i].name,
                traits[i].png,
                traits[i].on
            );
        }
    }
   

    function setPaperAddress(address _paperAddress) public onlyOwner {
        paperAddress = _paperAddress;
    }

    function flipMintMode() public onlyOwner {
        isMintActive = !isMintActive;
    }

    function flipAllowMode() public onlyOwner {
        isAllowListActive = !isAllowListActive;
    }


    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = 2;
        }
    }


    function setPayableWallet(address _payableWallet) external onlyOwner {
        payableWallet = payable(_payableWallet);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(payableWallet).transfer(balance);
    }



    /** *********************************** **/
    /** ******* Royalties Functions ******* **/
    /** *********************************** **/


    function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver,uint256 royaltyAmount) {

        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if (_royalties.length > 0) {
            return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
        }
        return (address(0), 0);

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
    

}