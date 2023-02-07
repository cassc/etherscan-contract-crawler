/**
    ┌─────────────────────────────────────────────────────────────────┐
    |             --- DEVELOPED BY JackOnChain (JOC) ---              |
    |          Looking for help to create your own contract?          |
    |                    Telgegram: JackTripperz                      |
    |                      Discord: JackT#8310                        |
    └─────────────────────────────────────────────────────────────────┘                                              
**/

// SPDX-License-Identifier: MIT

library Math {
    function add8(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0 && a != 0);
        return a**b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface ICocktailNFT is IERC721 {
    function minted() external view returns (uint256);

    function safeMint(address to) external;
}

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SpeakEasyMinting3 is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    ///@dev no constructor in upgradable contracts. Instead we have initializers
    function initialize() public initializer {
        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        __Ownable_init();
        SILVER_ADDRESS = 0xaC256FB4e7D7D2a882A4c2BE327a031b9cE78FEE; // mainnet
        EMP_SILVER_ADDRESS = 0xc78BB9c34CdF873FcCF787AF8d84DE42af45c540; // mainnet
        GOLD_ADDRESS = address(0); // mainnet
        PLATINUM_ADDRESS = address(0); // mainnet
        GT_ADDRESS = 0x77Fe17f2DFBBE22F40F017F104AfecE49bCCF006; // mainnet
        MARGARITA_ADDRESS = 0x62755Fec3c20ed2CbC1f4DcE19dBc13fc4492e60; // mainnet
        BLOODYMARY_ADDRESS = 0x40551fF067bB72266Cfc4f00c95b243d98cA3483; // mainnet
        PINACOLADA_ADDRESS = 0x0Ce0fFFB109255cD610eF53d4f8Ec0AC7131028D; // mainnet
        IRISHCOFFEE_ADDRESS = 0xEd35aC3c7f2DfAD24DF217A153F3609e20110fd6; // mainnet
        OLDFASHIONED_ADDRESS = 0x7Ab0424183fc12585D44Bee81429819473Bbf026; // mainnet

        STAFF_ADDRESS = 0x90849d08168D8D665cb45ae4BD3f9E6037C6E365;
        BANK_ADDRESS = 0xce238AddA1C558f213469d442128739a876fBB3d;
        OWNER_ADDRESS = _msgSender();
        _staff = payable(STAFF_ADDRESS);
        _bank = payable(BANK_ADDRESS);
        _owner = payable(OWNER_ADDRESS);
        MAX_WEEKLY_REWARDS_IN_BNB = 2000000000000000000; // 2 BNB
        MAX_TOTAL_DEPOSIT_SIZE = 20000000000000000000; // 20 BNB
        MAX_REFS = 25;
        MINT_COCKTAIL_COST = 500000000000000000; // 0.5 BNB
        MINT_COCKTAIL_LIMIT = 2000;
        MINT_MKC_COST = 250000000000000000; // 0.25 BNB
        MINT_MKC_LIMIT = 5000;

        _EMPsilverMKCNFT = ICocktailNFT(EMP_SILVER_ADDRESS);
        _silverMKCNFT = ICocktailNFT(SILVER_ADDRESS);
        _goldMKCNFT = ICocktailNFT(GOLD_ADDRESS);
        _platinumMKCNFT = ICocktailNFT(PLATINUM_ADDRESS);
        _bloodyMaryNft = ICocktailNFT(BLOODYMARY_ADDRESS);
        _ginAndTonicNft = ICocktailNFT(GT_ADDRESS);
        _irishCoffeeNft = ICocktailNFT(IRISHCOFFEE_ADDRESS);
        _margaritaNft = ICocktailNFT(MARGARITA_ADDRESS);
        _oldFashionedNft = ICocktailNFT(OLDFASHIONED_ADDRESS);
        _pinaColadaNft = ICocktailNFT(PINACOLADA_ADDRESS);

        _NOT_ENTERED = 1;
        _ENTERED = 2;
        _status = _NOT_ENTERED;
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    using Math for uint256;

    ICocktailNFT public _EMPsilverMKCNFT;
    ICocktailNFT public _silverMKCNFT;
    ICocktailNFT public _goldMKCNFT;
    ICocktailNFT public _platinumMKCNFT;
    ICocktailNFT public _bloodyMaryNft;
    ICocktailNFT public _ginAndTonicNft;
    ICocktailNFT public _irishCoffeeNft;
    ICocktailNFT public _margaritaNft;
    ICocktailNFT public _oldFashionedNft;
    ICocktailNFT public _pinaColadaNft;

    address private EMP_SILVER_ADDRESS;
    address private SILVER_ADDRESS;
    address private GOLD_ADDRESS;
    address private PLATINUM_ADDRESS;
    address private GT_ADDRESS;
    address private MARGARITA_ADDRESS;
    address private BLOODYMARY_ADDRESS;
    address private PINACOLADA_ADDRESS;
    address private IRISHCOFFEE_ADDRESS;
    address private OLDFASHIONED_ADDRESS;

    address private STAFF_ADDRESS;
    address private BANK_ADDRESS;
    address private OWNER_ADDRESS;
    address payable internal _staff;
    address payable internal _bank;
    address payable internal _owner;

    uint256 private MAX_WEEKLY_REWARDS_IN_BNB;
    uint256 private MAX_TOTAL_DEPOSIT_SIZE;
    uint32 private MAX_REFS;

    uint256 public MINT_COCKTAIL_COST;
    uint256 public MINT_COCKTAIL_LIMIT;
    uint256 public MINT_MKC_COST;
    uint256 public MINT_MKC_LIMIT;

    uint256 public totalUsers;
    bool public cocktailMintingEnabled;
    bool public silverMKCMintingEnabled;

    uint256 private _NOT_ENTERED;
    uint256 private _ENTERED;
    uint256 private _status;

    struct User {
        address adr;
        address upline;
        uint8 cocktailsMinted;
        uint8 silverMKCMinted;
        address[] referrals;
        uint8 silverEMPMKCMinted;
        address[] mintedCocktails;
    }

    mapping(address => User) internal users;

    event LogBytes(bytes data);

    event EmitMintedNFT(
        address indexed userAdr,
        address indexed refAdr,
        address indexed nftAdr
    );

    // Added in version 2:
    uint256 public MINT_EMP_MKC_COST;
    uint256 public MINT_EMP_MKC_LIMIT;
    bool public silverEMPMKCMintingEnabled;
    address public EMP_CONTRACT_ADDRESS;
    IERC20 public _empToken;

    function initEMPKMC() public onlyTeam {
        MINT_EMP_MKC_COST = 750000000000000000000; // 750 EMP
        MINT_EMP_MKC_LIMIT = 2000;
        silverEMPMKCMintingEnabled = false;
        EMP_CONTRACT_ADDRESS = 0x3b248CEfA87F836a4e6f6d6c9b42991b88Dc1d58; //mainnet;
        _empToken = IERC20(EMP_CONTRACT_ADDRESS);
    }
    /////////////////////

    modifier onlyTeam() {
        require(msg.sender == STAFF_ADDRESS || msg.sender == OWNER_ADDRESS);
        _;
    }

    function user(address adr) public view returns (User memory) {
        return users[adr];
    }

    function generateRandomNumber(uint256 arrayLength)
        private
        view
        returns (uint256)
    {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return (seed - ((seed / arrayLength) * arrayLength));
    }

    function mintRandomCocktail(address ref)
        public
        payable
        nonReentrant
    {
        require(cocktailMintingEnabled == true, "Cocktail minting disabled");
        require(
            hasMembership(msg.sender),
            "Must be invested to mint a random NFT"
        );
        require(msg.sender != ref, "Ref can't be the same as the one minting");
        require(
            msg.value == MINT_COCKTAIL_COST,
            "Input value isn't the required mint cost"
        );
        require(
            users[msg.sender].cocktailsMinted < 2,
            "One user can only mint 2 cocktails"
        );
        require(
            totalCocktailsMinted() < MINT_COCKTAIL_LIMIT,
            "Limit of cocktails minted has been reached"
        );

        uint256 rand = generateRandomNumber(100);
        address mintedNft = address(0);

        if (rand > 100) {
            revert("Incorrect random number");
        }
        if (rand <= 25) {
            mintCocktail(_ginAndTonicNft);
            mintedNft = GT_ADDRESS;
        }
        if (rand > 25 && rand <= 45) {
            mintCocktail(_margaritaNft);
            mintedNft = MARGARITA_ADDRESS;
        }
        if (rand > 45 && rand <= 63) {
            mintCocktail(_bloodyMaryNft);
            mintedNft = BLOODYMARY_ADDRESS;
        }
        if (rand > 63 && rand <= 78) {
            mintCocktail(_pinaColadaNft);
            mintedNft = PINACOLADA_ADDRESS;
        }
        if (rand > 78 && rand <= 90) {
            mintCocktail(_irishCoffeeNft);
            mintedNft = IRISHCOFFEE_ADDRESS;
        }
        if (rand > 90 && rand <= 100) {
            mintCocktail(_oldFashionedNft);
            mintedNft = OLDFASHIONED_ADDRESS;
        }

        users[msg.sender].mintedCocktails.push(mintedNft);

        users[msg.sender].cocktailsMinted = Math.add8(
            users[msg.sender].cocktailsMinted,
            1
        );

        if (
            ref != address(0) &&
            users[msg.sender].upline == address(0) &&
            hasMembership(ref) &&
            users[ref].referrals.length < 5
        ) {
            users[msg.sender].upline = ref;
            users[ref].referrals.push(msg.sender);
            payable(ref).transfer(percentFromAmount(msg.value, 20));
            _bank.transfer(percentFromAmount(msg.value, 80));
        } else {
            _bank.transfer(msg.value);
        }

        emit EmitMintedNFT(msg.sender, ref, mintedNft);
    }

    function percentFromAmount(uint256 amount, uint256 fee)
        private
        pure
        returns (uint256)
    {
        return Math.div(Math.mul(amount, fee), 100);
    }

    function totalCocktailsMinted() public view returns (uint256) {
        return
            _ginAndTonicNft
                .minted()
                .add(_margaritaNft.minted())
                .add(_bloodyMaryNft.minted())
                .add(_pinaColadaNft.minted())
                .add(_irishCoffeeNft.minted())
                .add(_oldFashionedNft.minted());
    }

    function totalSilverMKCMinted() public view returns (uint256) {
        return _silverMKCNFT.minted().add(_EMPsilverMKCNFT.minted());
    }

    function mintCocktail(ICocktailNFT _cocktailNFT)
        private
        returns (bool success)
    {
        try _cocktailNFT.safeMint(msg.sender) {
            return true;
        } catch (bytes memory reason) {
            emit LogBytes(reason);
            return false;
        }
    }

    function mintSilverMKC() public payable nonReentrant {
        require(silverMKCMintingEnabled == true, "SilverMKC minting disabled");
        require(
            msg.value == MINT_MKC_COST,
            "Input value isn't the required mint cost"
        );
        require(
            users[msg.sender].silverMKCMinted == 0 &&
                users[msg.sender].silverEMPMKCMinted == 0,
            "One user can only mint 1 SilverMKC"
        );
        require(
            totalSilverMKCMinted() < MINT_MKC_LIMIT,
            "Limit of MKC's minted has been reached"
        );

        try _silverMKCNFT.safeMint(msg.sender) {
            _bank.transfer(msg.value);
        } catch (bytes memory reason) {
            emit LogBytes(reason);
        }

        users[msg.sender].silverMKCMinted = Math.add8(
            users[msg.sender].silverMKCMinted,
            1
        );

        emit EmitMintedNFT(msg.sender, address(0), SILVER_ADDRESS);
    }

    function mintEMPSilverMKC(uint256 tokens) public nonReentrant {
        require(
            silverEMPMKCMintingEnabled == true,
            "EMP SilverMKC minting disabled"
        );
        require(
            tokens == MINT_EMP_MKC_COST,
            "Input value isn't the required mint cost"
        );
        require(
            users[msg.sender].silverEMPMKCMinted == 0 &&
                users[msg.sender].silverMKCMinted == 0,
            "One user can only mint 1 SilverMKC"
        );
        require(
            totalSilverMKCMinted() < MINT_EMP_MKC_LIMIT,
            "Limit of MKC's minted has been reached"
        );

        try _EMPsilverMKCNFT.safeMint(msg.sender) {
            bool success = _empToken.transferFrom(
                address(msg.sender),
                address(BANK_ADDRESS),
                tokens
            );
            if (success == false) {
                revert("EMP contract token transfer failed");
            }
        } catch (bytes memory reason) {
            emit LogBytes(reason);
        }

        users[msg.sender].silverEMPMKCMinted = Math.add8(
            users[msg.sender].silverEMPMKCMinted,
            1
        );

        emit EmitMintedNFT(msg.sender, address(0), EMP_SILVER_ADDRESS);
    }

    function changeMKCPrice(uint256 newPrice) public onlyTeam {
        MINT_MKC_COST = newPrice;
    }

    function changeEMPMKCPrice(uint256 newPrice) public onlyTeam {
        MINT_EMP_MKC_COST = newPrice;
    }

    function changeCocktailPrice(uint256 newPrice) public onlyTeam {
        MINT_COCKTAIL_COST = newPrice;
    }

    function enableCocktailMinting(bool enable, uint256 limit)
        public
        onlyTeam
        returns (bool enabled, uint256 newLimit)
    {
        cocktailMintingEnabled = enable;
        if (limit > 0) {
            MINT_COCKTAIL_LIMIT = limit;
        }
        return (cocktailMintingEnabled, MINT_COCKTAIL_LIMIT);
    }

    function enableSilverMKCMinting(bool enable, uint256 limit)
        public
        onlyTeam
        returns (bool enabled, uint256 newLimit)
    {
        silverMKCMintingEnabled = enable;
        if (limit > 0) {
            MINT_MKC_LIMIT = limit;
        }
        return (silverMKCMintingEnabled, MINT_MKC_LIMIT);
    }

    function enableEMPSilverMKCMinting(bool enable, uint256 limit)
        public
        onlyTeam
        returns (bool enabled, uint256 newLimit)
    {
        silverEMPMKCMintingEnabled = enable;
        if (limit > 0) {
            MINT_EMP_MKC_LIMIT = limit;
        }
        return (silverEMPMKCMintingEnabled, MINT_EMP_MKC_LIMIT);
    }

    function hasMembership(address adr) public view returns (bool) {
        return
            _silverMKCNFT.balanceOf(adr) > 0 ||
            _EMPsilverMKCNFT.balanceOf(adr) > 0;
    }
}