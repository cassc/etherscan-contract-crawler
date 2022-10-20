// SPDX-License-Identifier: MIT
/*
    SOMFactory / 2022
*/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "./Coward.sol";

contract SOMFactory is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable, IERC2981Upgradeable {
    address public CowardAddress;

    using Counters for Counters.Counter;

    bool private isInitialized;

    Counters.Counter private _tokenIds;

    struct SOM {
        uint256 tokenId;
        uint256 state;
    }
    
    address public adminAddress;
    uint256 public constant DENOMINATOR = 100;
    uint256 public TotalMintCount = 0;

    //Variables for Mint logic
    uint256 public MINT_PRICE = 2500000000000000;
    // uint256 public MINT_PRICE = 0;
    address public BankAddress;
    address public devAddress;

    //Variables for Mint logic 
    uint256[1001] private Randomorder;
    mapping(address => uint256) public NFTcountPerAddress;
    mapping(address => bool) public WhiteList;

    //Token URIs
    string public _baseTokenURI;
    string public _unrevealedURI;

    bool public isRevealed = false;
    bool public PublicSaleStarted = false;

    //Variables for Game
    mapping(uint256 => SOM) public soms;

    event SOMMinted();

    function initialize(
        string memory baseTokenURI_,
        string memory unrevealedURI_,
        address _adminAddress,
        address _BankAddress,
        address _devAddress,
        uint256[] memory randomorder_
    ) public initializer {
        __ERC721_init("Sons Of Mars", "SOM");
        __Ownable_init();
        _baseTokenURI = baseTokenURI_;
        _unrevealedURI = unrevealedURI_;
        isInitialized = true;
        adminAddress = _adminAddress;
        BankAddress = _BankAddress;
        devAddress = _devAddress;
        
        for (uint256 i = 0 ; i < randomorder_.length; i ++) {
            Randomorder[i] = randomorder_[i];
        }
    }

    
    modifier onlySOM() {
        require(
            adminAddress == msg.sender || owner() == msg.sender || CowardAddress == msg.sender, "RNG: Caller is not the SOM address"
        );
        _;
    }

    function isInitialize() external view returns(bool) {
        return isInitialized;
    }

    //Basical settings

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;  
    }

    // function setBaseURI(string calldata _newURI) external onlySOM {
    //     _baseTokenURI = _newURI;
    // }

    // function setAdminAddress(address _address) external onlySOM {
    //     adminAddress = _address;
    // }

    // function setMintPrice(uint256 _price) external onlySOM {
    //     MINT_PRICE = _price;
    // }

    function setWhiteList(address[] memory _addresses) external onlySOM {
        for(uint256 i = 0; i < _addresses.length; i ++) {
            WhiteList[_addresses[i]] = true;
        }
    }

    function setStartPublicMint() external onlySOM {
        PublicSaleStarted = true;
    }

    function setRevealed() external onlySOM {
        isRevealed = true;
        CowardGambit(CowardAddress).endRound();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI;
        if(isRevealed == true) {
            currentBaseURI = _baseURI();
        }
        else {
            currentBaseURI = _unrevealedURI;
            return currentBaseURI;
        }
        
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString((Randomorder[tokenId - 1] - 1) * 19 + soms[tokenId].state), "")) : "";
    }

    //for Coward contract

    function setCowardAddress(address _address) external onlySOM {
        CowardAddress = _address;
    }

    function getSOMarray(uint256 _tokenId) onlySOM public view returns (uint256) {
        return soms[_tokenId].state;
    }

    function setSOMarray(uint256 _tokenId, uint256 _state) onlySOM public {
        soms[_tokenId].state = _state;
    }

    //Mint logic

    function mint(uint256 _mintAmount) external payable {
        require(_mintAmount + totalSupply() < 1001, "Overflow amount!");
        if(PublicSaleStarted == false) {
            require(WhiteList[msg.sender] == true, "You didn't join WhiteList!");
        }

        uint256 restAmount = 0;
        if(msg.sender != adminAddress) {
            require(msg.value >= MINT_PRICE * _mintAmount, "Invalid Amount");
            require(NFTcountPerAddress[msg.sender] + _mintAmount < 4, "Can't mint over 3 NFTs!");
            restAmount = msg.value - MINT_PRICE * _mintAmount;
            payable(BankAddress).transfer(MINT_PRICE * _mintAmount * 95 / DENOMINATOR);
            payable(devAddress).transfer(MINT_PRICE * _mintAmount * 5 / DENOMINATOR);
            payable(msg.sender).transfer(restAmount);
        }

        for (uint256 k = 0; k < _mintAmount; k++) {

            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            soms[tokenId] = SOM({
                tokenId: tokenId,
                state: 1
            });

            TotalMintCount ++;
            CowardGambit(CowardAddress).setJoinItems(soms[tokenId].tokenId, soms[tokenId].state);
            NFTcountPerAddress[msg.sender] ++;
        }

        emit SOMMinted();
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        uint256 payout = (_salePrice * 10) / DENOMINATOR;
        // emit RoyaltyInfo_Secondary(_recipient, payout, _tokenId);
        return (BankAddress, payout);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721EnumerableUpgradeable, IERC165Upgradeable)
    returns (bool)
    {
        return (
        interfaceId == type(IERC2981Upgradeable).interfaceId ||
        super.supportsInterface(interfaceId)
        );
    }

    function Burn(uint256 _tokenId) public {
        _burn(_tokenId);
    }
    
    function fetchSOMs() external view returns (SOM[] memory) {
        uint256 itemCount = _tokenIds.current(); 
        SOM[] memory items = new SOM[](itemCount);

        for (uint256 i = 0; i < itemCount; i++) {
            if(soms[i + 1].state == 20) continue;
            SOM memory currentItem = soms[i + 1];
            items[i] = currentItem;
        }
        return items;
    }
    function fetchMySOMs(address _address) external view returns(SOM[] memory) {

        uint256 itemCount = 0;
        for(uint256 i = 0; i < _tokenIds.current(); i++) {
            if(soms[i + 1].state == 20) continue;
            address owner = ownerOf(i + 1);
            if(owner == _address) itemCount ++;
        }

        SOM[] memory myItems = new SOM[](itemCount);
        
        itemCount = 0;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if(soms[i + 1].state == 20) continue;
            address owner = ownerOf(i + 1);
            if(owner == _address) {
                SOM memory item = soms[i + 1];
                myItems[itemCount ++] = item;
            }
        }
        return myItems;
    }
}