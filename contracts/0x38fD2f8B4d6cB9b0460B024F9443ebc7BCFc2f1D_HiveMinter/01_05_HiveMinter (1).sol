// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ITheGardens {
    function hiveMint(address _to, uint256 _amount) external;
    function totalSupply() external view returns (uint256);
}

contract HiveMinter is Ownable {
    ITheGardens public theGardens;
    address public beekeeper;
    uint256 public price = 0.065 ether;
    uint256 public discount = 0.025 ether;
    uint16 public immutable maxSupply = 10000;
    uint8 public maxMintAmount = 20;

    event Minted(address indexed _to, uint8 _amount);

    error AccessError();
    error Disabled();
    error NotEnoughEther();
    error MaxSupply();
    error WithdrawFailed();
    error MinterIsContract();
    error MaxMintAmount();

    constructor(address _mintBees, address _beekeeper) {
        theGardens = ITheGardens(_mintBees);
        beekeeper = _beekeeper;
    }

    modifier onlyBeekeeper() {
        if (
            msg.sender != beekeeper &&
            msg.sender != owner()
        ) {
            revert AccessError();
        }
        _;
    }

    modifier maxMint(uint256 _amount) {
        if (_amount + theGardens.totalSupply() > maxSupply) {
            revert MaxSupply();
        }
        _;
    }

    modifier mintLimiter(uint256 _amount) {
        if (_amount > maxMintAmount) {
            revert MaxMintAmount();
        }
        _;
    }

    /**
     * @dev Modifier to ensure that the caller is not a contract. This is useful for
     *      preventing potential exploits or automated actions from contracts.
     *      Reverts the transaction with a `MinterNotContract` error if the caller is a contract.
     */
    modifier beeCallerOnly() {
        // Revert the transaction if the caller is a contract
        if (msg.sender != tx.origin) {
            revert MinterIsContract();
        }

        _;
    }

    function setBeekeeper(address _beekeeper) public onlyOwner {
        beekeeper = _beekeeper;
    }

    function setLimit(uint8 _limit) public onlyBeekeeper {
        maxMintAmount = _limit;
    }

    function setDiscount(uint256 _discount) public onlyBeekeeper {
        discount = _discount;
    }

    function setPrice(uint256 _price) public onlyBeekeeper {
        price = _price;
    }

    function withdraw() public onlyBeekeeper {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    function grabPrice(
        uint256 _amount
    ) public view returns (uint256) {
        unchecked {
            uint256 finalPrice = price * _amount;

            if (_amount > 4) {
                uint256 numIncrements = _amount / 5;
                uint256 discountPrice = discount * numIncrements;
                finalPrice = finalPrice - discountPrice;
            }

            return finalPrice;
        }
    }

    function mint(
        uint8 _amount
    ) public payable maxMint(_amount) mintLimiter(_amount) beeCallerOnly {
        uint256 _price = grabPrice(_amount);

        if (msg.value < _price) revert NotEnoughEther();
        emit Minted(msg.sender, _amount);
        theGardens.hiveMint(msg.sender, _amount);
        
    }
}