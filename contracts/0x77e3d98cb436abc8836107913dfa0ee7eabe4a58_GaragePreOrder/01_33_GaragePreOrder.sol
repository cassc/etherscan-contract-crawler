// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.13;

import "./GarageToken.sol";
import "./GarageFactory.sol";
import "./IDSValue.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./BZNFeed.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes memory data
    ) external payable returns (bool);
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
interface ERC20Basic {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface BurnableToken is ERC20 {
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) external;
}

interface StandardBurnableToken is BurnableToken {
    function burnFrom(address _from, uint256 _value) external;
}

contract GaragePreOrder is Ownable, ApproveAndCallFallBack {
    using SafeMath for uint256;

    //Event for when a garage has been bought
    event GaragesBought(uint256 garageId, address owner, uint16 category);
    //Event for when ether is taken out of this contract
    event Withdrawal(uint256 amount);

    //Default referal commision percent
    uint256 public constant COMMISSION_PERCENT = 5;

    enum CategoryState {
        NULL,
        EXISTS_NOT_OPEN,
        EXISTS_OPEN,
        KILLED
    }

    struct CategoryData {
        //Whether category is open
        CategoryState state;
        //The percent increase and percent base for a given category
        uint256 percentIncrease;
        uint256 percentBase;
        //Minting fee for category
        uint256 mintingFee;
        //Price of a givevn category in BZN WEI
        uint256 categoryPrice;
    }

    mapping(uint16 => CategoryData) public categoryData;

    //The additional referal commision percent for any given referal address (default is 0)
    mapping(address => uint256) internal commissionRate;

    //Opensea buy address
    address internal constant OPENSEA =
        0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;

    //The percent of ether required for buying in BZN
    bool public allowCreateCategory = true;

    //The garage token contract
    GarageToken public token;
    //The garage factory contract
    GarageFactory internal factory;
    //The BZN contract
    StandardBurnableToken internal bzn;
    //The gamepool address
    address internal gamePool;

    //Require the skinned/regular shop to be opened
    modifier ensureShopOpen(uint16 category) {
        require(
            categoryData[category].state == CategoryState.EXISTS_OPEN,
            "Category not open or doesnt exist"
        );
        _;
    }

    //Allow function to accept BZN payment
    modifier payInBZN(
        address referal,
        uint16 category,
        address payable new_owner,
        uint16 quanity
    ) {
        uint256[] memory prices = new uint256[](4); //Hack to work around local var limit (nextPrice, bznPrice, commision, totalPrice)
        (prices[0], prices[3]) = priceFor(category, quanity);
        require(prices[0] > 0, "Price not yet set");

        categoryData[category].categoryPrice = prices[0];

        prices[1] = prices[3]; //Convert the totalPrice to BZN

        //The commissionRate map adds any partner bonuses, or 0 if a normal user referral
        if (referal != address(0)) {
            prices[2] =
                (prices[1] * (COMMISSION_PERCENT + commissionRate[referal])) /
                100;
        }

        uint256 requiredEther = categoryData[category].mintingFee;

        require(
            msg.value >= requiredEther,
            "Buying with BZN requires some Ether!"
        );

        bzn.burnFrom(new_owner, (((prices[1] - prices[2]) * 30) / 100));
        bzn.transferFrom(
            new_owner,
            gamePool,
            prices[1] - prices[2] - (((prices[1] - prices[2]) * 30) / 100)
        );

        _;

        if (msg.value > requiredEther) {
            new_owner.transfer(msg.value - requiredEther);
        }

        if (referal != address(0)) {
            require(referal != msg.sender, "The referal cannot be the sender");
            require(
                referal != tx.origin,
                "The referal cannot be the tranaction origin"
            );
            require(
                referal != new_owner,
                "The referal cannot be the new owner"
            );

            bzn.transferFrom(new_owner, referal, prices[2]);

            prices[2] =
                (requiredEther *
                    (COMMISSION_PERCENT + commissionRate[referal])) /
                100;

            address payable _referal = payable(referal);

            _referal.transfer(prices[2]);
        }
    }

    //Constructor
    constructor(
        address tokenAddress,
        address tokenFactory,
        address gp,
        address bzn_address
    ) {
        token = GarageToken(tokenAddress);

        factory = GarageFactory(tokenFactory);

        bzn = StandardBurnableToken(bzn_address);

        gamePool = gp;

        //Set percent increases
        /* categoryData[1] = CategoryData(
            CategoryState.EXISTS_NOT_OPEN,
            1001,
            1000,
            0,
            0
        );
        categoryData[2] = CategoryData(
            CategoryState.EXISTS_NOT_OPEN,
            100025,
            100000,
            0,
            0
        );
        categoryData[3] = CategoryData(
            CategoryState.EXISTS_NOT_OPEN,
            100015,
            100000,
            0,
            0
        ); */

        commissionRate[OPENSEA] = 10;
    }

    function createCategory(uint16 category) public onlyOwner {
        require(allowCreateCategory);
        require(categoryData[category].state == CategoryState.NULL);

        categoryData[category] = CategoryData(
            CategoryState.EXISTS_NOT_OPEN,
            0,
            0,
            0,
            0
        );
    }

    function categoryExists(uint16 category) public view returns (bool) {
        return categoryData[category].state == CategoryState.EXISTS_OPEN;
    }

    function disableCreateCategories() public onlyOwner {
        allowCreateCategory = false;
    }

    //Set the referal commision rate for an address
    function setCommission(address referral, uint256 percent) public onlyOwner {
        require(percent > COMMISSION_PERCENT);
        require(percent < 95);
        percent = percent - COMMISSION_PERCENT;

        commissionRate[referral] = percent;
    }

    function setMintingFee(uint16 category, uint256 fee) public onlyOwner {
        categoryData[category].mintingFee = fee;
    }

    //Set the price increase/base for skinned or regular garages
    function setPercentIncrease(
        uint256 increase,
        uint256 base,
        uint16 category
    ) public onlyOwner {
        require(increase > base);

        categoryData[category].percentIncrease = increase;
        categoryData[category].percentBase = base;
    }

    function killCategory(uint16 category) public onlyOwner {
        require(categoryData[category].state != CategoryState.KILLED);

        categoryData[category].state = CategoryState.KILLED;
    }

    //Open/Close the skinned or regular garages shop
    function setShopState(uint16 category, bool open) public onlyOwner {
        require(
            categoryData[category].state == CategoryState.EXISTS_NOT_OPEN ||
                categoryData[category].state == CategoryState.EXISTS_OPEN
        );

        categoryData[category].state = open
            ? CategoryState.EXISTS_OPEN
            : CategoryState.EXISTS_NOT_OPEN;
    }

    /**
     * Set the price for any given category in USD.
     */
    function setPrice(
        uint16 category,
        uint256 price,
        bool inWei
    ) public onlyOwner {
        uint256 multiply = 1e18;
        if (inWei) {
            multiply = 1;
        }

        categoryData[category].categoryPrice = price * multiply;
    }

    /**
    Withdraw the amount from the contract's balance. Only the contract owner can execute this function
    */
    function withdraw(uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;

        require(amount <= balance, "Requested to much");

        address payable _owner = payable(owner());

        _owner.transfer(amount);

        emit Withdrawal(amount);
    }

    //Buy many skinned or regular garages with BZN. This will reserve the amount of garages and allows the new_owner to invoke claimGarages for free
    function buyWithBZN(
        address referal,
        uint16 category,
        address payable new_owner,
        uint16 quanity
    )
        public
        payable
        ensureShopOpen(category)
        payInBZN(referal, category, new_owner, quanity)
        returns (bool)
    {
        factory.mintFor(new_owner, quanity, category);

        return true;
    }

    /**
    Get the price for skinned or regular garages in USD (wei)
    */
    function priceFor(uint16 category, uint16 quanity)
        public
        view
        returns (uint256, uint256)
    {
        require(quanity > 0);
        uint256 percent = categoryData[category].percentIncrease;
        uint256 base = categoryData[category].percentBase;

        uint256 currentPrice = categoryData[category].categoryPrice;
        uint256 nextPrice = currentPrice;
        uint256 totalPrice = 0;
        //We can't use exponents because we'll overflow quickly
        //Only for loop :(
        for (uint256 i = 0; i < quanity; i++) {
            nextPrice = (currentPrice * percent) / base;

            currentPrice = nextPrice;

            totalPrice += nextPrice;
        }

        //Return the next price, as this is the true price
        return (nextPrice, totalPrice);
    }

    //Determine if a tokenId exists (has been sold)
    function sold(uint256 _tokenId) public view returns (bool) {
        return token.exists(_tokenId);
    }

    function receiveApproval(
        address from,
        uint256,
        address tokenContract,
        bytes memory data
    ) public payable override returns (bool) {
        require(tokenContract == address(bzn), "Invalid token");

        address referal;
        uint16 category;
        uint16 quanity;

        (referal, category, quanity) = abi.decode(
            data,
            (address, uint16, uint16)
        );

        require(quanity >= 1);

        address payable _from = payable(from);

        buyWithBZN(referal, category, _from, quanity);

        return true;
    }
}