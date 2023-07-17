// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract AtemPassport is ERC721Enumerable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 5000;
    uint256 public constant MAX_ELEMENTS_WHITELIST = 500;
    uint256 public constant PRICE = 0;
    uint256 public constant MINIMUM_ETH_BALANCE = 3 * 10**17;
    uint256 public constant MAX_BY_MINT = 15;
    address public constant creatorAddress = 0x2a99AE1d91654c4Ea571d44F60661cCA3AE22498;
    
    string public baseTokenURI;
    bool private _pause;
    bool private _init_whitelist;
    uint256 private _whitelist_count = 0;
    uint256 private _whitelist_minted_count = 0;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public claimList;

    event JoinGang(uint256 indexed id);
    constructor(string memory baseURI) ERC721("AtemNftPassport", "ANP") {
        setBaseURI(baseURI);
        pause(false);
        _init_whitelist = false;
        _initwhitelist();
    }
    function getWhitelistCount() public view returns (uint256) {
        return _whitelist_count;
    }
    function addwhitelist(address _addr) public onlyOwner {
        require(getWhitelistCount() < MAX_ELEMENTS_WHITELIST, "Whitelist ended!");
        whitelist[_addr] = true;
        _whitelist_count = _whitelist_count + 1;

    }
    function _initwhitelist() private {
        require(!_init_whitelist, "Whitelist already initialized!");

        // Team
        addwhitelist(0x71E084AB76a113727cdB1d10B0e9B1041a51eD07);
        addwhitelist(0xa25FA9F141Ef211ff3AC22Ad1738F9c472b34896);
        addwhitelist(0xb2BcB680D243aBCBFfA7dE5498Ab55a975EA82eC);
        addwhitelist(0x6922E36C987daE1787497cA2d242F4e78E57d954);
        addwhitelist(0x799bb25A0dee15cc95BF3E30F0fAE625c89b4AF5);
        addwhitelist(0x3A8925D66781Da2ac300490cE83cD10e844f35aB);
        addwhitelist(0x8bca2440FFC51BAd2b4B8b484B97B83C42f21fcf);
        addwhitelist(0xc6dA722D9159533C080432feeeb8e7C0a5658a46);
        addwhitelist(0xa447838252397297a8da4C42b6CbbFfe17743EFC);
        addwhitelist(0x1EE99C2502786A62021408C57b9bFcb20aB88a29);
        addwhitelist(0xe853E70B31401dfEFeDb0EfB130a1d19b462f3a5);
        addwhitelist(0x3B958ae6F6d63De991af7cE733F672df0C81348b);
        addwhitelist(0x514c4BA193c698100DdC998F17F24bDF59c7b6fB);
        addwhitelist(0x3eAa45909af51E889323a4B6AF1862B5d77b79ce);

        // Referal
        addwhitelist(0xDe9a9425b3CE28f66719eA606B1d1FDda210A94d);
        addwhitelist(0x8C702A9a6e0cd14a53251C630743c4F5327eddE8);

        // Campaign
        addwhitelist(0x27a886862492783cB03eb0c44261809C8915ed27);
        addwhitelist(0xcB6702d9541761E51d3547e600Dd58ae2ba41052);
        addwhitelist(0xfB9ecC10FA880B77A92C2CD50DF0fc760312fa7A);
        addwhitelist(0xfe9C86d79067617174af2fc0C871092225b71511);
        addwhitelist(0xDa830d2D83A57Cea255bCfD0Cf89C3e94Abde0FD);
        addwhitelist(0xcB6702d9541761E51d3547e600Dd58ae2ba41052);

        // Applicants
        addwhitelist(0x52E78e68Be7F0F38eE1e62078265bf331112949B);
        addwhitelist(0x1C24bC23804e5575c72dF62B271C6a0b6FbbF3B3);
        addwhitelist(0x02802fdb01F9D5d014aFc00AFE8C349f3b06a688);
        addwhitelist(0xC71DA7095111d8D1F7CCB7e58624d66a447d1Fd2);
        addwhitelist(0xe62BCf78a4b157b10969720A44d6438c7aD99F5c);
        addwhitelist(0x68e22c812C5637E846a2c9c126E94E87989A829e);
        addwhitelist(0xAdfE477Ca193a91DEff121617eea367a319096cc);
        addwhitelist(0xB7179D22828fc2C13a0b1805ee03972378fd52F9);
        addwhitelist(0x623A0f4897983Dc106F601c6dC89f2Deff49C714);
        // addwhitelist(0x141721f4d7fd95541396e74266ff272502ec8899);
        addwhitelist(0xDe3943BE6CF95B57C032C7e9F507119CdFb71ed2);
        addwhitelist(0x6BcD5373208a68Ad692212E103006C689e1Cd149);
        addwhitelist(0x9f115e2Fe40B2E33d588E1fd292A7D52dFCc5163);
        addwhitelist(0x82960053861eA85FE646d0397DeCE18B8C0e3c59);
        addwhitelist(0x8C702A9a6e0cd14a53251C630743c4F5327eddE8);
        addwhitelist(0x410a0887cC91cCf1e8Db56422b9a5D8B078c2200);
        addwhitelist(0xDc93fEF5564989471d0AC9b047a95A5c8491b002);
        addwhitelist(0x958bD0B0EC3D36a2B5BED6bA4A24e40E91Eb789A);
        addwhitelist(0xa3EA91b1071F08B90241377eB4E229EBA48f38CC);
        addwhitelist(0x8A0456f448f58AD2135554248FB9212D4D81fa1A);
        addwhitelist(0xA25f2D38cB91F53136C25E553641E341D1cbd07f);
        addwhitelist(0xa5049BF5a2875188304E3c03483c96944fbf8f94);
        addwhitelist(0xAF4D9E13dC0F2E2d3Ec0a17972dB215E77c3F83C);
        addwhitelist(0x8D5b48934c0C408ADC25F14174c7307922F6Aa60);
        addwhitelist(0x9d09Ec3CBb97Bc6571168A155cAd17043Ff1093D);
        addwhitelist(0xF8759f7F4762B49627E65B589C12dfCbb3BDE37F);
        addwhitelist(0x57b07f71766233Ff17dBb0283eC873660cDBaf81);
        addwhitelist(0xD1570080bcB784b4F5E378dfd4cDfFDfd6C110f6);
        addwhitelist(0x9F2bfede7710490BeC05c8723B072651dBfdEd45);
        addwhitelist(0xfE38b737537065F6D9e157d8c3C639Fa042382Cd);
        addwhitelist(0x811639E18a3C2dFF9755D60b7832fa22F200a6f0);
        addwhitelist(0x63c24F164Fa69f4dB7f45F211a8e089c157B4747);
        addwhitelist(0x5e7C21DefE711bCd5CEa1B267d2e87F7913D510F);
        addwhitelist(0x682c72e317Cf93A36Ace26d52f9eB9c41712e56C);
        addwhitelist(0x75aD930bACC1328acD9A6e869379efa30a3727E3);
        addwhitelist(0x87d63B96ca7695775fddE18ADE27480143F9dfA0);
        addwhitelist(0xe6E4b47a79d0Bb2135DE2F2D8466790D7a1e99A3);
        addwhitelist(0xF1aC2C73D2e5d30b78874552E640D48490f9fe42);
        addwhitelist(0x95F50Cf888dFeC90321dC376c1E695F15B081595);
        addwhitelist(0x5db63f987817910Bbb9656B5210990408d3831fB);
        addwhitelist(0x06175bB4c2F213FF8B1e123e5f77312a47aE3364);
        addwhitelist(0xc8d60B0899fd738FcC2cF84ED1A5fcB62b9f2521);
        addwhitelist(0x25aD2667B19e866109c1a93102b816730a6Aec3f);
        addwhitelist(0x80f800c9f5cB252f4a3ea892cd1E38c299bCdcbF);
        addwhitelist(0x6D5F2Fb7582B4b1d9b5ccfEbA60126dE7Da9D02C);
        addwhitelist(0x0F5994afdF8C01351A37e501Cd28A961D76Da66e);

        // Community Leo
        addwhitelist(0x14c798426f2Bb6ac40CDeBFf2Dc078bF56e6C34d);
        addwhitelist(0xB80aED37a3437DBbf97BF46056d009C01cf847Fb);
        addwhitelist(0xdE3df72601b79acec367eECc2d126BD946ACB320);
        addwhitelist(0x3980d2fF1323f22f38bf18894294d46F7ab1aa6d);
        addwhitelist(0x3c3C0A24013f73b27eAE88032C04001A2dC12771);
        // addwhitelist(0x58db6b78d60babd5ec5b1b3759029d4ed70cb728);
        // addwhitelist(0x598de2667e561bbee88b6e779de46a4cab0e5ccb);
        addwhitelist(0xC43BC524904B7CD004ED6F7F301e09115c22cc90);
        addwhitelist(0xFA312871af0b5369c1e479ac8f4D87CE575e9443);
        addwhitelist(0xbEadbf314A7B17140f5964249803d649D5491C8A);
        addwhitelist(0xe7FA93f1E789870351401cc2d38A7925755cD4f2);
        // addwhitelist(0x5d2c96f66eb8d8fa69b2408122e30bfa991570af);
        addwhitelist(0x14c798426f2Bb6ac40CDeBFf2Dc078bF56e6C34d);
        addwhitelist(0x7C8b7A4d00B68bFDbA0db6e5Ce1895cAB9AC0CcE);
        addwhitelist(0x8665E6A5c02FF4fCbE83d998982E4c08791b54e5);
        addwhitelist(0x08D5450A4Bf45d1F8a86Ef3E9Ae2E618760E917C);
        addwhitelist(0xef3DFf08EdAB3f21fD25bCd14a4ea9023BF0d602);
        addwhitelist(0x5EB5dca8267a4113490c87743e66D76832CEE43d);
        addwhitelist(0xBd923B473D145A91cEAf12BB66a8007d1eEb1C61);
        addwhitelist(0x9a7960DC84b778Fa5cc1200b013eB1B71FFD1f6a);
        // addwhitelist(0x5d2c96f66eb8d8fa69b2408122e30bfa991570af);
        addwhitelist(0x9731c556A8F285fA33Ff3dec4aDd14784b944036);
        addwhitelist(0x2B50b585cb928c6b06498229db8276e882DC3B6B);
        addwhitelist(0xFd19276756130aAabD95DB2545Ac54c65A09B6C4);

        // Community Eric
        addwhitelist(0x6588eA04ebf8C8021469B72eFb1da1Faf0F0023A);
        addwhitelist(0x82960053861eA85FE646d0397DeCE18B8C0e3c59);
        addwhitelist(0x87B7Cf1956df30C5D216C72c894422277aAA13d6);
        addwhitelist(0xDA048BED40d40B1EBd9239Cdf56ca0c2F018ae65);
        addwhitelist(0xC5972F891f207B7Fe1bd10894A30Eb013aAF353E);
        addwhitelist(0x1BF555E99b9056e75F5752EBF6593C4929BF5d50);
        addwhitelist(0x216f91Ce3c1CB358E583441d6179c6c19c834A2E);
        addwhitelist(0x5EB5dca8267a4113490c87743e66D76832CEE43d);
        addwhitelist(0xBd923B473D145A91cEAf12BB66a8007d1eEb1C61);
        addwhitelist(0x9a7960DC84b778Fa5cc1200b013eB1B71FFD1f6a);
        addwhitelist(0x786297c4947408E01A1a977FDa4dB5E53A09c461);
        addwhitelist(0xeE2343f8C3efd59ea73b909809d8fA300B133dEC);
        addwhitelist(0xf997558AE6aB4e5b7DF35B6686becf512A50202c);
        addwhitelist(0x9bD1F59AFe81c7b23517985CB7B6eca30314e6b8);

        // NFT Creators
        addwhitelist(0x0bd8a10088773ACaa1a3F1a65fd547c8C8C3d65A);
        addwhitelist(0xE879a374Fc1cC246c51EC720749A1251a86c8a93);
    
        _init_whitelist = true;
    }


    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!_pause, "Pausable: paused");
        }
        _;
    }
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function isPaused() public view returns (bool) {
        return _pause;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(super.tokenURI(tokenId), ""));
    }
    
    function hasAtemNft(address _addr) public view returns (bool) {
      if(balanceOf(_addr) > 0) {
          return true;
      }
      return false;
    }
    function isMintable() public view returns (bool) {
        require(!isPaused(), "paused by owner");
        if(msg.sender == creatorAddress) {
            return true;
        }

        if(claimList[msg.sender]) {
            return false;
        }

        address user = msg.sender;
        uint256 user_ether_balance = user.balance;
        
        if(whitelist[user] == true) {
            return true;
        }
        else if(user_ether_balance >= MINIMUM_ETH_BALANCE && _totalSupply() - _whitelist_minted_count < MAX_ELEMENTS - MAX_ELEMENTS_WHITELIST) {
            return true;
        }

        return false;
    }
    function mint() public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total <= MAX_ELEMENTS, "Sale end");
        require(isMintable(), "Not allowed to mint");
        
        _mintAnElement(msg.sender);
        claimList[msg.sender] = true;

        if(whitelist[msg.sender] == true) {
            _whitelist_minted_count = _whitelist_minted_count + 1;
        }
    }
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id + 1);
        emit JoinGang(id + 1);
    }
    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        _pause = val;
    }

    function transferOwner(address newOwner) public onlyOwner {
        transfer(newOwner);
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function reserve(uint256 _count) public onlyOwner {
        uint256 total = _totalSupply();
        require(total + _count <= 100, "Exceeded");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_msgSender());
        }
    }
    
}