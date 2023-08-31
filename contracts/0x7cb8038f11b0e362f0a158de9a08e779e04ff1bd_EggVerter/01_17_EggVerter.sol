// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title EggVerter
 * @dev This contract represents an egg conversion system where eggs can be purchased with Dino tokens or Ether. 
 * Eggs can be claimed and used to mint Dino Badges. The contract is also ERC721 and ERC2981 compliant.
 */
contract EggVerter is ERC721, ERC721Burnable, Ownable, ERC2981 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    /* interfaces */
    IERC20 public dinoToken;
    ERC721 public eggToken;
    //counter for nfts
    Counters.Counter public _tokenIDcounter;
    /* addresses */
    address distributionWallet;
    address public dinoReceiver;
    /* strings */
    string public baseURI;
    string public baseExtension = ".json";
    /* uints */
    uint256 public eggCostWithDino = 1000 * 10 ** 18;
    uint256 public eggCostWithEth = 1 ether;
    uint256 public eggsRequiredToClaim = 20;
    uint256[] public depositedEggIds;
    /* booleans */
    bool public saleOpened = false;
    bool public badgeClaimOpen = false;

    mapping(address => uint256) public eggsBoughtByOwner;
    mapping(uint256 => bool) private eggIDsSold;
    
    /**
     * @dev Initializes the EggVerter contract.
     * @param _dinoToken The address of the Dino token contract.
     * @param _royaltyWallet The address of the royalty wallet.
     * @param _eggToken The address of the egg token contract.
     * //dino token address: 0x49642110B712C1FD7261Bc074105E9E44676c68F
     * //egg nft address: 
     */
    constructor(address _dinoToken, address _royaltyWallet, address _eggToken)
    ERC721("DinoBadge", "DINOb")
    {
        eggToken = ERC721(_eggToken);
        dinoToken = IERC20(_dinoToken);
        _setDefaultRoyalty(_royaltyWallet, 1000);
    }

    /**
     * @dev Allows the purchase of eggs.
     * @param quantity The quantity of eggs to purchase.
     * @param _buyingWithEther Boolean indicating whether the purchase is made with Ether or Dino tokens.
     * @notice caller of function must give this contract approval for accessing erc-20 token if _buyingWithEther = false
     */
    function buyEggs(uint256 quantity, bool _buyingWithEther) public payable {
        require(saleOpened, "sale is not open");
        require(quantity > 0, "Quantity must be greater than 0");
        require(
            eggToken.isApprovedForAll(distributionWallet, address(this)),
            "Designated wallet approval not set"
        );
        require(
            depositedEggIds.length > 0,
            "No eggs have been initialized for transfer"
        );

        if (_buyingWithEther) {
            require(
                msg.value >= eggCostWithEth * quantity,
                "Not enough ether sent"
            );
        } else {
            (bool transferOccured) = dinoToken.transferFrom(
                msg.sender,
                address(this),
                eggCostWithDino * quantity
            );
            require(transferOccured, "Transfer failed. No approval most likely.");
        }

        uint256 eggSentCount = 0;
        uint256 currentIndex = 0;

        while (eggSentCount < quantity && currentIndex < depositedEggIds.length) {
            uint256 eggId = depositedEggIds[currentIndex];
            if (!eggIDsSold[eggId]) {
                eggToken.safeTransferFrom(
                    distributionWallet,
                    msg.sender,
                    eggId
                );
                eggIDsSold[eggId] = true;
                eggSentCount++;
                eggsBoughtByOwner[msg.sender]++;
            }
            currentIndex++;
        }

        emit EggPurchased(msg.sender, quantity);
    }

    /**
     * @dev Allows the contract owner to withdraw unsold eggs.
     */
    function withdrawEggs() public onlyOwner {
        uint256 eggSentCount = 0;
        uint256 currentIndex = 0;
        uint256 depositedEggIdLength = depositedEggIds.length;

        while (currentIndex < depositedEggIdLength) {
            uint256 eggId = depositedEggIds[currentIndex];
            if (!eggIDsSold[eggId]) {
                eggIDsSold[eggId] = true;
                eggSentCount++;
            }
            currentIndex++;
        }

        depositedEggIds = new uint256[](0);
    }

    /**
     * @dev Allows the contract owner to deposit eggs into the contract.
     * @param eggIDs The array of egg token IDs to deposit.
     */
    function depositEggs(uint256[] memory eggIDs)
        public
        onlyOwner
    {
        require(
            eggToken.isApprovedForAll(distributionWallet, address(this)),
            "Designated wallet must have approval to commence deposit"
        );

        for (uint256 i = 0; i < eggIDs.length; i++) {
            if (eggToken.ownerOf(eggIDs[i]) == distributionWallet) {
                depositedEggIds.push(eggIDs[i]);
                eggIDsSold[eggIDs[i]] = false;
            } else {
                emit EggIdInvalid(eggIDs[i]);
            }
        }
    }

    /**
     * @dev Allows the contract owner to withdraw the contract's Ether balance.
     */
    function withdrawEther() public onlyOwner {
        uint256 contractEthBal = address(this).balance;
        payable(msg.sender).transfer(contractEthBal);
    }

    /**
     * @dev Allows the contract owner to set the designated wallet address.
     * @param _wallet The new designated wallet address.
     */
    function addDesignatedWallet(address _wallet) public onlyOwner {
        distributionWallet = _wallet;
    }

    /**
     * @dev Overrides ERC2981 and ERC721 functions to support the corresponding interfaces.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the count of deposited eggs that are not sold.
     * @return depositedEggCount The count of deposited eggs.
     */
    function returnDepositedTokenAmt() public view returns (uint256) {
        uint256 depositedEggCount = 0;

        for (uint256 i = 0; i < depositedEggIds.length; i++) {
            if (!eggIDsSold[depositedEggIds[i]]) {
                depositedEggCount++;
            }
        }
        return depositedEggCount;
    }
    /**
    *@dev toggles the state to enable nft sales
    */
    function toggleSaleState() public onlyOwner {
        saleOpened = !saleOpened;
    }

    /**
     * @dev Allows the contract owner to set the Ether cost for purchasing eggs.
     * @param _newCost The new Ether cost for purchasing eggs.
     */
    function setEthCost(uint256 _newCost) public onlyOwner {
        eggCostWithEth = _newCost;
    }

    /**
     * @dev Allows the contract owner to set the Dino token cost for purchasing eggs.
     * @param _newCost The new Dino token cost for purchasing eggs. only input whole tokens. decimal calc is done already.
     */
    function setDinoCost(uint256 _newCost) public onlyOwner {
        eggCostWithDino = _newCost * 10 ** 18;
    }
    /**
     * @dev Allows contract owner to modify the dinoReceiver address for dino withdrawals
     * @param _receiver the address of new dino token receiver
     */
    
    function addDinoReceiver(address _receiver) public onlyOwner {
        dinoReceiver = _receiver;
    }
    /**
     * @dev Allows the contract owner to burn the DinoToken balance.
     */
    function sendDinoTokens() public onlyOwner
    {
        uint256 dinoBalance = dinoToken.balanceOf(address(this));
        bool dinoSent = dinoToken.transfer(dinoReceiver, dinoBalance);
        require(dinoSent, "problem with dino transfer");
    }

    /* Dino Badge -- can be created for egg purchases or a premier purchase */

    /**
     * @dev Allows the contract owner to set the base URI for token metadata.
     * @param _newURI The new base URI for token metadata.
     */
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    /**
     * @dev Overrides the internal _baseURI function to return the base URI for token metadata.
     * @return The base URI for token metadata.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Overrides the tokenURI function to return the URI for a given token ID.
     * @param tokenId The ID of the token.
     * @return The URI for the given token ID.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /**
     * @dev Allows the user to claim a Dino Badge if they meet the requirements.
     */
    function claimDinoBadge() public {
        require(
            badgeClaimOpen,
            "Badge claim isn't ready yet. Try back later."
        );
        require(
            checkIsClaimable(msg.sender),
            "Sorry, you haven't claimed enough eggs to earn a badge."
        );

        _tokenIDcounter.increment();
        uint256 tokenid = _tokenIDcounter.current();
        _safeMint(msg.sender, tokenid);
    }

    /**
     * @dev Checks if a user is eligible to claim a Dino Badge.
     * @param _checker The address of the user to check.
     * @return A boolean indicating whether the user is eligible to claim a badge.
     */
    function checkIsClaimable(address _checker) public view returns (bool) {
        if (eggsBoughtByOwner[_checker] >= eggsRequiredToClaim) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Allows the contract owner to set the amount of eggs required to claim a Dino Badge.
     * @param _newAmount The new amount of eggs required to claim a badge.
     */
    function setClaimableAmount(uint256 _newAmount) public onlyOwner {
        eggsRequiredToClaim = _newAmount;
    }

    /**
     * @dev Allows the contract owner to toggle the badge claim status.
     */
    function toggleBadgeClaim() public onlyOwner {
        badgeClaimOpen = !badgeClaimOpen;
    }

    /**
     * @dev Event emitted when eggs are purchased.
     * @param _buyer The address of the buyer.
     * @param _quantity The quantity of eggs purchased.
     */
    event EggPurchased(address _buyer, uint256 _quantity);
    event EggIdInvalid(uint256 indexed tokenIDs);
}