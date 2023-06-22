// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IApes.sol";
import "./interface/ITraits.sol";
import "./interface/IRandomizer.sol";
import "./interface/IMasterContract.sol";

/// @title Bulls and Apes Project - Loot Box
/// @author BAP Dev Team
/// @notice Loot Boxes to get ERC1155 Traits for Apes
contract LootBoxes is ERC1155Holder, Ownable, ReentrancyGuard {
    /// @notice Cooldown period for power replenishment
    uint256 public constant POWER_COOLDOWN = 12 hours;
    /// @notice Cooldown period free spins opening
    uint256 public freeSpinsCooldown = 10 minutes;

    /// @notice BAP Apes contract
    IApes public apesContract;
    /// @notice BAP Traits contract
    ITraits public traitsContract;
    /// @notice BAP Randomizer contract
    /// @dev Used to pick random winners on box opening
    IRandomizer public randomizerContract;
    /// @notice BAP Master contract
    /// @dev Used for functions that require METH or Utilities contract interaction
    IMasterContract public masterContract;
    address public secret;

    /// @notice Last timestamp Ape opened a common box
    mapping(uint256 => uint256) public apeLastBox;
    /// @notice Last timestamp Ape used a free spin
    mapping(uint256 => uint256) public apeLastFreeSpin;
    /// @notice Count for Ape common box re-opening
    mapping(uint256 => uint256) public apeOpenCount;
    /// @notice Prices for METH bags
    mapping(uint256 => uint256) public bagPrice;

    mapping(bytes => bool) private isSignatureUsed;

    event BoxOpened(
        uint256 boxType,
        uint256 apeId,
        uint256 amount,
        uint256 price,
        uint256[] prizes
    );

    event SpecialBoxOpened(
        uint256 boxType,
        uint256 amount,
        uint256 price,
        uint256[] prizes,
        address operator
    );

    event MethBagBought(uint256 amount, uint256 price, address to);
    event MethBagCreated(uint256 amount, uint256 price, address operator);

    /// @notice Deploys the contract
    /// @param apesAddress Address of Apes contract
    /// @param traitsAddress Address of Traits contract
    /// @param randomizerAddress Address of Randomizer contract
    /// @param masterContractAddress Address of Master contract
    /// @param signer Address used to provide signatures
    /// @dev Used for functions that require METH or Utilities contract interaction
    constructor(
        address apesAddress,
        address traitsAddress,
        address randomizerAddress,
        address masterContractAddress,
        address signer
    ) {
        apesContract = IApes(apesAddress);
        traitsContract = ITraits(traitsAddress);
        randomizerContract = IRandomizer(randomizerAddress);
        masterContract = IMasterContract(masterContractAddress);
        secret = signer;
    }

    /// @notice Open a Common box using an specific Ape
    /// @param apeId ID of the Ape used to open the box
    /// @param amount Amount of boxes to be opened
    /// @param price Price to be paid for open the boxes (in METH)
    /// @param boxType Box type code: 0 - common, 1 - epic, 2 - legendary
    /// @param timeOut Timestamp for signature expiration
    /// @param hasPower Ape power flag
    /// @param randomSeed Bytes seed to generate the random winner
    /// @param signature Signature to verify above parameters
    /// @dev Mints amount ERC1155 Traits to the sender
    function openCommonBox(
        uint256 apeId,
        uint256 amount,
        uint256 price,
        uint256 boxType,
        uint256 timeOut,
        bool hasPower,
        bytes calldata randomSeed,
        bytes calldata signature
    ) external {
        require(!isSignatureUsed[signature], "OpenBox: Signature already used");
        require(timeOut > block.timestamp, "OpenBox: Seed is no longer valid");
        require(boxType == 0, "OpenBox: BoxType not valid");

        address tokenOwner = apesContract.ownerOf(apeId);

        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(
                        msg.sender,
                        tokenOwner,
                        apeId,
                        amount,
                        price,
                        boxType,
                        timeOut,
                        hasPower,
                        randomSeed
                    )
                ),
                signature
            ),
            "OpenBox: Signature is invalid"
        );

        isSignatureUsed[signature] = true;

        if (price > 0) {
            if (
                !hasPower ||
                apeLastBox[apeId] + POWER_COOLDOWN > block.timestamp
            ) {
                require(
                    apeLastBox[apeId] + 5 minutes > block.timestamp,
                    "OpenBox: Re open time elapsed"
                );

                if (apeOpenCount[apeId] > 0) {
                    price = price * 2;
                } else {
                    price = (price * 3000) / 2000;
                    apeOpenCount[apeId]++;
                }
            } else {
                apeOpenCount[apeId] = 0;
            }

            apeLastBox[apeId] = block.timestamp;

            masterContract.pay(price, price);
        } else {
            require(
                apeLastFreeSpin[apeId] + freeSpinsCooldown > block.timestamp,
                "OpenBox: Free spins cooldown"
            );
            apeLastFreeSpin[apeId] = block.timestamp;
        }

        (uint256[] memory prizes, bool hasExtra) = randomizerContract.getRandom(
            randomSeed,
            amount,
            timeOut
        );

        uint256[] memory prizesAmounts = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            prizesAmounts[i] = 1;
        }

        traitsContract.mintBatch(msg.sender, prizes, prizesAmounts);

        emit BoxOpened(boxType, apeId, amount, price, prizes);
    }

    /// @notice Open a Epic or Legendary box
    /// @param amount Amount of boxes to be opened
    /// @param price Price to be paid for open the boxes (in ETH)
    /// @param boxType Box type code: 0 - common, 1 - epic, 2 - legendary
    /// @param timeOut Timestamp for signature expiration
    /// @param randomSeed Bytes seed to generate the random winner
    /// @param signature Signature to verify above parameters
    /// @dev Mints amount ERC1155 Traits to the sender
    function openSpecialBox(
        uint256 amount,
        uint256 price,
        uint256 boxType,
        uint256 timeOut,
        bytes calldata randomSeed,
        bytes calldata signature
    ) external payable {
        require(!isSignatureUsed[signature], "OpenBox: Signature already used");
        require(timeOut > block.timestamp, "OpenBox: Seed is no longer valid");
        require(boxType > 0, "OpenBox: BoxType not valid");
        require(msg.value == price, "OpenBox: Wrong ETH value");

        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(
                        msg.sender,
                        amount,
                        price,
                        boxType,
                        timeOut,
                        randomSeed
                    )
                ),
                signature
            ),
            "OpenBox: Signature is invalid"
        );

        isSignatureUsed[signature] = true;

        (uint256[] memory prizes, bool hasExtra) = randomizerContract.getRandom(
            randomSeed,
            amount,
            timeOut
        );

        uint256 quantiteToMint = amount;

        if (hasExtra) {
            for (uint256 i = 0; i < prizes.length; i++) {
                uint256 currentPrize = prizes[i];

                if (currentPrize > 39 && currentPrize < 44) {
                    masterContract.airdrop(msg.sender, 1, currentPrize);
                    quantiteToMint--;
                }
            }

            if (quantiteToMint > 0) {
                uint256[] memory prizesToMint = new uint256[](quantiteToMint);
                uint256[] memory prizesAmounts = new uint256[](quantiteToMint);
                uint256 addedCount;

                for (uint256 i = 0; i < prizes.length; i++) {
                    uint256 currentPrize = prizes[i];
                    if (currentPrize > 39 && currentPrize < 44) {
                        continue;
                    }

                    prizesAmounts[addedCount] = 1;
                    prizesToMint[addedCount] = currentPrize;
                    addedCount++;
                }

                traitsContract.mintBatch(
                    msg.sender,
                    prizesToMint,
                    prizesAmounts
                );
            }
        } else {
            uint256[] memory prizesAmounts = new uint256[](quantiteToMint);

            for (uint256 i = 0; i < quantiteToMint; i++) {
                prizesAmounts[i] = 1;
            }

            traitsContract.mintBatch(msg.sender, prizes, prizesAmounts);
        }

        emit SpecialBoxOpened(boxType, amount, price, prizes, msg.sender);
    }

    /// @notice Buy METH bags
    /// @param amount Amount of METH to buy
    /// @param to Address to send the METH
    /// @param price Price to be paid for the METH (in ETH)
    /// @param timeOut Timestamp for signature expiration
    /// @param signature Signature to verify above parameters
    /// @dev Mints amount METH to selected address
    function buyMethBag(
        uint256 amount,
        address to,
        uint256 price,
        uint256 timeOut,
        bytes calldata signature
    ) external payable {
        require(timeOut > block.timestamp, "buyMethBag: Seed is no longer valid");
        require(
            _verifyHashSignature(
                keccak256(abi.encode(amount, to, price, timeOut)),
                signature
            ),
            "buyMethBag: Signature is invalid"
        );
        require(price > 0, "Buy METH bag: amount is not valid");
        require(msg.value == price, "Buy METH bag: not enough ETH to buy");

        masterContract.claim(to, amount);

        emit MethBagBought(amount, price, to);
    }

    /// @notice Set the price for a METH bag
    /// @param amount Amount of METH for the bag
    /// @param price Price in WEI to be paid for the bag
    /// @dev METH bags can only be created by the owner
    function setMethBagPrice(uint256 amount, uint256 price) external onlyOwner {
        require(amount > 0, "METH amount: can't be 0");

        bagPrice[amount] = price;

        emit MethBagCreated(amount, price, msg.sender);
    }

    /// @notice Change the signer address
    /// @param signer Address used to provide signatures
    /// @dev Signer address can only be set by the owner
    function setSecret(address signer) external onlyOwner {
        secret = signer;
    }

    /// @notice Change the cooldown perion on free spins
    /// @param newCooldown New cooldown set on seconds
    /// @dev newCooldown can only be set by the owner
    function setFreeSpinCooldown(uint256 newCooldown) external onlyOwner {
        freeSpinsCooldown = newCooldown;
    }

    /// @notice Change contract Addresses
    /// @param apesAddress Address of Apes contract
    /// @param traitsAddress Address of Traits contract
    /// @param randomizerAddress Address of Randomizer contract
    /// @param masterContractAddress Address of Master contract
    /// @dev Can only be set by the owner
    function setContractAddresses(
        address apesAddress,
        address traitsAddress,
        address randomizerAddress,
        address masterContractAddress
    ) external onlyOwner {
        apesContract = IApes(apesAddress);
        traitsContract = ITraits(traitsAddress);
        randomizerContract = IRandomizer(randomizerAddress);
        masterContract = IMasterContract(masterContractAddress);
    }

    function withdrawETH(address _address, uint256 amount)
        public
        nonReentrant
        onlyOwner
    {
        require(amount <= address(this).balance, "Insufficient funds");
        (bool success, ) = _address.call{value: amount}("");
        require(success, "Unable to send eth");
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}