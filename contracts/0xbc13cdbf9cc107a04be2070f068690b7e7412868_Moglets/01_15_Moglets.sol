pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Moglets is ERC721, Ownable {
    using SafeMath for uint256;
    // This is the original provenance record of all Moglets in existence at the time.
    string public constant ORIGINAL_PROVENANCE = "04599dff4da3cfc3cf2397b8a97ba24bba2168dbc5556fe9225230b9349af8d6";

    // Maximum amount of Moglets in existance. Ever.
    uint256 public constant MAX_MOGLET_SUPPLY = 10000;

    // The block in which the starting index was created.
    uint256 public startingIndexBlock;

    // The index of the item that will be #1.
    uint256 public startingIndex;

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _setBaseURI(baseURI);
    }

    /**
    * @dev Gets current Moglet price based on current supply.
    */
    function getMogletsMaxAmount() public view returns (uint256) {
        require(totalSupply() < MAX_MOGLET_SUPPLY, "Sale has already ended, no more Moglets left to sell.");
        return 20;
    }

    /**
    * @dev Gets current Moglets price based on current supply.
    */
    function getMogletsPrice() public view returns (uint256) {
        require(totalSupply() < MAX_MOGLET_SUPPLY, "Sale has already ended.");

        uint256 currentSupply = totalSupply();

        if (currentSupply >= 9900) {
            return  480000000000000000;        // 9000-9999:  0.48 ETH
        } else if (currentSupply >= 9400) {
            return  320000000000000000;        // 8000-8999:  0.32 ETH
        } else if (currentSupply >= 7500) {
            return  240000000000000000;        // 7000-7999:  0.24 ETH
        } else if (currentSupply >= 4500) {
            return  160000000000000000;        // 4500-6999:  0.16 ETH
        } else if (currentSupply >= 2500) {
            return   80000000000000000;        // 2500-4499:  0.08 ETH
        } else if (currentSupply >= 1000) {
            return   40000000000000000;        // 1000-2499:  0.04 ETH
        } else if (currentSupply >= 500) {
            return   20000000000000000;        // 500-999:   0.02 ETH
        } else {
            return   10000000000000000;        /// 0-499:    0.01 ETH
        }
    }

    /**
    * @dev Mints yourself a Moglets. Or more. You do you.
    */
    function mintAMoglet(uint256 numberOfMoglets) public payable {
        // Some exceptions that need to be handled.
        require(totalSupply() < MAX_MOGLET_SUPPLY, "Sale has already ended.");
        require(numberOfMoglets > 0, "You cannot mint 0 Moglets.");
        require(numberOfMoglets <= getMogletsMaxAmount(), "You are not allowed to buy this many Moglets at once in this price tier.");
        require(SafeMath.add(totalSupply(), numberOfMoglets) <= MAX_MOGLET_SUPPLY, "Exceeds maximum Moglets supply. Please try to mint less Moglets.");
        require(SafeMath.mul(getMogletsPrice(), numberOfMoglets) == msg.value, "Amount of Ether sent is not correct.");

        // Mint the amount of provided Moglets.
        for (uint i = 0; i < numberOfMoglets; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }

        // Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        // Set the starting block index when the sale concludes either time-wise or the supply runs out.
        if (startingIndexBlock == 0 && (totalSupply() == MAX_MOGLET_SUPPLY)) {
            startingIndexBlock = block.number;
        }
    }

    /**
    * @dev Finalize starting index
    */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_MOGLET_SUPPLY;

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_MOGLET_SUPPLY;
        }

        // Prevent default sequence because that would be a bit boring.
        if (startingIndex == 0) {
            startingIndex = SafeMath.add(startingIndex, 1);
        }
    }

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function changeBaseURI(string memory baseURI) onlyOwner public {
       _setBaseURI(baseURI);
    }

    function reserveGiveaway() public onlyOwner {
      uint currentSupply = totalSupply();
      require(currentSupply <= 50, "Already given away");
      uint256 index;
      // Reserved for people who helped this project and giveaways
      for (index = 0; index < 50; index++) {
          _safeMint(owner(), currentSupply + index);
      }
    }
}