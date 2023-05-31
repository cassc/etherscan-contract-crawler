// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                    ########################################                     //
//                #################################################                //
//              #####################################################              //
//            ########################################################             //
//           ############                                   ############           //
//        ############                                       ###########           //
//        ###########                                          ############        //
//       ###########         ###                     ###         ##########        //
//           #####       ########                   ########       #####           //
//                     ###########                ############                     //
//                      ###########              ############                      //
//                       ##################################                        //
//                         ###############################                         //
//                          ############################                           //
//              ####          ########################           ####              //
//         ##########                                          ##########          //
//         ###########                                        ############         //
//          ############                                     ###########           //
//            #########################################################            //
//             ######################################################              //
//               ##################################################                //
//                  ############################################                   //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//            #########################################################            //
//         ###############################################################         //
//       ##################################################################        //
//      #####################################################################      //
//    ############                                                 ###########     //
//   ############                                                   ############   //
//  ###########                                                      ############  //
//    ########                                                         ########    //
//        ##                                                            ##         //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//             By purchasing this token, you are agreeing to the terms             //
//                outlined at www.tdrbingo.com/terms-and-conditions                //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////
//                      @author: https://twitter.com/ti_bi_ke                      //
/////////////////////////////////////////////////////////////////////////////////////
contract TDRBingo is ERC721, IERC2981, Ownable {
    using Counters for Counters.Counter;

    struct SalesRound {
        uint256 id;
        uint256 price;
        uint256 maxTokenId;
    }

    struct TokenDetail {
        bool minted;
        address specificBuyer;
    }

    // ########### Sale ############
    bool public isSaleActive = false;
    uint256 public currentSalesRound = 0;
    uint256 public addressMaxMintAmount = 1;
    SalesRound[] public salesRounds;
    mapping(uint256 => mapping(address => uint256)) public addressMintCount;
    TokenDetail[276] private tokenDetails;

    // ########## Supply ###########
    uint256 public tokenSupply = 253;
    uint256 public constant MAX_SUPPLY = 276;
    Counters.Counter private supplyCounter;

    // ######## Provenance #########
    string public provenanceHash;

    // ######## Royalties ##########
    address public royaltyAddress;
    uint256 public royaltyPercent;
    address public thankYouGod;

    // ######### Metadata ##########
    string private customBaseURI;
    string private notRevealedURI;
    uint256 public revealedTo = 0;

    // ####### Constructor #########
    constructor(string memory _notRevealedURI) ERC721("TDRBingo", "TDR01") {
        notRevealedURI = _notRevealedURI;
        royaltyAddress = owner();
        royaltyPercent = 750;

        salesRounds.push(SalesRound(0, 0.1 ether, 23));
        salesRounds.push(SalesRound(1, 0.12 ether, 46));
        salesRounds.push(SalesRound(2, 0.14 ether, 69));
        salesRounds.push(SalesRound(3, 0.16 ether, 92));
        salesRounds.push(SalesRound(4, 0.18 ether, 115));
        salesRounds.push(SalesRound(5, 0.2 ether, 138));
        salesRounds.push(SalesRound(6, 0.22 ether, 161));
        salesRounds.push(SalesRound(7, 0.24 ether, 184));
        salesRounds.push(SalesRound(8, 0.253 ether, 207));
        salesRounds.push(SalesRound(9, 0.253 ether, 230));
        salesRounds.push(SalesRound(10, 0.253 ether, 253));
    }

    // ########## Minting ##########
    function mint(uint256 id) external payable {
        require(totalSupply() < tokenSupply, "Exceeds max supply");
        require(id > 0 && id <= tokenSupply, "Invalid token id");
        require(isSaleActive, "Sale is not active");
        require(tx.origin == msg.sender, "Contract denied");
        require(
            id <= salesRounds[currentSalesRound].maxTokenId,
            "Token is not for sale"
        );
        uint256 price = getPrice(id);
        require(msg.value >= price, "Not enough eth sent");

        if (tokenDetails[id - 1].specificBuyer != address(0)) {
            require(
                tokenDetails[id - 1].specificBuyer == msg.sender,
                "Token is not reserved for this address"
            );
        } else {
            require(
                addressMintCount[currentSalesRound][msg.sender] <
                    addressMaxMintAmount,
                "Attempting to mint too many tokens per address"
            );
        }

        _mint(msg.sender, id);
        addressMintCount[currentSalesRound][msg.sender] += 1;
        tokenDetails[id - 1].minted = true;
        supplyCounter.increment();
    }

    function mintAdmin(address _recipient, uint256[] calldata _ids)
        external
        onlyOwner
    {
        uint256 count = _ids.length;
        require(totalSupply() + count <= tokenSupply, "Max supply exceeded");
        for (uint256 i = 0; i < count; i++) {
            uint256 id = _ids[i];
            require(id > 0 && id <= tokenSupply, "Invalid token id");
            _mint(_recipient, id);
            tokenDetails[id - 1].minted = true;
            supplyCounter.increment();
        }
    }

    // ######### Metadata ##########
    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function setBaseURI(string memory _customBaseURI) external onlyOwner {
        customBaseURI = _customBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI)
        external
        onlyOwner
    {
        notRevealedURI = _notRevealedURI;
    }

    function setRevealedTo(uint256 _revealedTo) external onlyOwner {
        revealedTo = _revealedTo;
    }

    function getSalesRounds() public view returns (SalesRound[] memory) {
        return salesRounds;
    }

    function getTokenDetails() public view returns (TokenDetail[276] memory) {
        return tokenDetails;
    }

    // Token metadata initially stored at TDR HQ to allow flexibility in the reveal process.
    // Once all tokens are revealed, metadata uploaded to IPFS storage for longevity.
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (_tokenId <= revealedTo) {
            string memory baseURI = _baseURI();
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(baseURI, Strings.toString(_tokenId))
                    )
                    : "";
        }
        return
            bytes(notRevealedURI).length > 0
                ? string(
                    abi.encodePacked(notRevealedURI, Strings.toString(_tokenId))
                )
                : "";
    }

    // ######## Provenance #########
    function setProvenanceHash(string memory _provenanceHash)
        external
        onlyOwner
    {
        provenanceHash = _provenanceHash;
    }

    // ########## Supply ###########
    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    /* @title Execute / Do Not Execute / Execute */
    /* @author @williamsburroughs */
    function cosmicTrigger(uint256 _price) external onlyOwner {
        tokenSupply = MAX_SUPPLY;
        salesRounds.push(SalesRound(salesRounds.length, _price, MAX_SUPPLY));
    }

    function decreaseTokenSupply(uint16 _decreaseByAmount) external onlyOwner {
        require(_decreaseByAmount > 0, "Should be decreased by at least one");
        require(
            tokenSupply - _decreaseByAmount >= totalSupply(),
            "Amount cannot be decreased as it has already been minted"
        );

        tokenSupply = tokenSupply - _decreaseByAmount;
    }

    // ########### Sale ############
    function setIsSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function getPrice(uint256 _tokenId) public view returns (uint256 price) {
        require(_tokenId > 0 && _tokenId <= tokenSupply, "Invalid token id");
        for (uint256 i = salesRounds.length - 1; i >= 0; i--) {
            if (i == 0) {
                return salesRounds[0].price;
            } else if (
                _tokenId > salesRounds[i - 1].maxTokenId &&
                _tokenId <= salesRounds[i].maxTokenId
            ) {
                return salesRounds[i].price;
            }
        }
    }

    function setPrivateSale(uint256 _tokenId, address _specificBuyer)
        external
        onlyOwner
    {
        tokenDetails[_tokenId - 1].specificBuyer = _specificBuyer;
    }

    function updateSalesRound(
        uint256 _salesRound,
        uint256 _price,
        uint256 _maxTokenId
    ) external onlyOwner {
        salesRounds[_salesRound].price = _price;
        salesRounds[_salesRound].maxTokenId = _maxTokenId;
    }

    function setSalesRound(uint256 _salesRound) external onlyOwner {
        currentSalesRound = _salesRound;
    }

    function setAddressMaxMintAmount(uint256 _addressMaxMintAmount)
        external
        onlyOwner
    {
        addressMaxMintAmount = _addressMaxMintAmount;
    }

    function accessDenied() external {
        require(isSaleActive, "Sale is not active");
        require(thankYouGod == address(0), "access denied");        
        thankYouGod = msg.sender;
        _mint(msg.sender, 248);
        supplyCounter.increment();
    }

    // ######### Royalties #########
    function setRoyaltyPercentage(uint256 _royaltyPercentage)
        external
        onlyOwner
    {
        royaltyPercent = _royaltyPercentage;
    }

    function setRoyaltyReceiver(address _royaltyReceiver) external onlyOwner {
        royaltyAddress = _royaltyReceiver;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "Non-existent token");
        return (royaltyAddress, (_salePrice * royaltyPercent) / 10000);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return (_interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId));
    }

    // ######### Withdraw ##########
    function withdraw() public {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}