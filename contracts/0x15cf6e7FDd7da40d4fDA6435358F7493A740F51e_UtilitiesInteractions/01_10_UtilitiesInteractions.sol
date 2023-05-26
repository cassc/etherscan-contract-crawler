// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

import "./interface/IMasterContract.sol";
import "./reduced_interfaces/BAPGenesisInterface.sol";
import "./reduced_interfaces/BAPTeenBullsInterface.sol";
import "./reduced_interfaces/BAPUtilitiesInterface.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Bulls and Apes Project - Utilities Interactions
/// @author BAP Dev Team
/// @notice Handle the use of the utilities inside BAP ecosystem
contract UtilitiesInteractions is Ownable, IERC721Receiver {
    using Strings for uint256;
    /// @notice Master contract instance
    IMasterContract public masterContract;
    /// @notice OG Bulls contract instance
    BAPGenesisInterface public bapGenesis;
    /// @notice Teen Bulls contract instance
    BAPTeenBullsInterface public bapTeenBulls;
    /// @notice Utility contract instance
    BAPUtilitiesInterface public bapUtilities;

    /// @notice Address of the wallet that signs messages
    address public secret;

    /// @notice Cooldown period for METH bank withdraw
    uint256 public withdrawCoolDown = 1 hours;
    /// @notice Max amount of Merger Orbs that can be purchased
    uint256 public constant MERGER_ORB_AMOUNT = 1490;
    /// @notice Utility ID for the Merger Orb
    uint256 public constant MERGER_ORB = 2;
    /// @notice counter for Merger Orbs purchased
    uint256 public mergerOrbCounter = 0;
    /// @notice Last token received, Used for resurrecting
    uint256 private lastTokenReceived;

    /// @notice Boolean to prevent Teens being sent to the contract, only allowed when reviving
    bool private isReviving = false;

    /// @notice Mapping of User last withdraw from METH bank
    mapping(address => uint256) public lastWithdraw;

    /// @notice Mapping to check if a Teen has been resurrected
    mapping(uint256 => bool) public isResurrected;
    /// @notice Mapping to identify God Bulls
    mapping(uint256 => bool) public isGod;

    /// @notice Mapping to check if a signature has been used
    mapping(bytes => bool) public usedSignatures;

    /// @notice Resurrection event
    event TeenResurrected(
        address user,
        uint256 sacrificed,
        uint256 resurrected,
        uint256 newlyMinted,
        uint256 offChainUtility
    );

    /// @notice Event emitted during on-chain Replenish
    event BreedingReplenish(address user, uint256 tokenId, uint256 timestamp);

    /// @notice Event emitted during on-chain Merger Orb purchase
    event MergerOrbBought(address user, uint256 timestamp);

    /// @notice Event for off chain payment for Merger Orb
    event OffChainMethPayment(address user, uint256 amount, uint256 timestamp);

    /// @notice Event for off chain minting of the Merger Orb
    event MergerOrbOffChainMint(address user, uint256 timestamp);

    /// @notice Event for Utility burned off chain
    event UtilityBurnedOffChain(
        address user,
        uint256 utilityId,
        uint256 timestamp
    );

    /// @notice Event for Utilities burned on chain as deposit
    event UtilityBurnedOnChain(
        address user,
        uint256[] utilityIds,
        uint256[] amounts,
        uint256 timestamp
    );

    /// @notice Event for Utilities off chain being minted
    event UtilitiesMinted(
        address user,
        uint256[] utilityIds,
        uint256[] amounts,
        uint256 timestamp
    );

    /// @notice Event for METH withdrawn from the bank
    event MethWithdrawn(address user, uint256 amount, bytes signature, uint256  timestamp);

    /// @notice Deploys the contract and sets the instances addresses
    /// @param masterContractAddress: Address of the Master Contract
    /// @param genesisAddress: Address of the OG Bulls contract
    /// @param teensAddress: Address of the Teen Bulls contract
    /// @param utilitiesAddress: Address of the Utilities contract
    /// @dev Sets the God Bulls that IDs are less than 10000
    constructor(
        address masterContractAddress,
        address genesisAddress,
        address teensAddress,
        address utilitiesAddress
    ) {
        masterContract = IMasterContract(masterContractAddress);
        bapGenesis = BAPGenesisInterface(genesisAddress);
        bapTeenBulls = BAPTeenBullsInterface(teensAddress);
        bapUtilities = BAPUtilitiesInterface(utilitiesAddress);

        isGod[2016] = true;
        isGod[3622] = true;
        isGod[3714] = true;
        isGod[4473] = true;
        isGod[4741] = true;
        isGod[5843] = true;
        isGod[6109] = true;
        isGod[7977] = true;
        isGod[8190] = true;
        isGod[9690] = true;

        mergerOrbCounter = bapUtilities.mergerOrbsPurchased();
    }

    /// @notice Handle the resurrection of a Teen Bull
    /// @param utilityId: ID of the utility used to resurrect
    /// @param sacrificed: ID of the Teen Bull sacrificed
    /// @param resurrected: ID of the Teen Bull to resurrect
    /// @param timeOut: Time out for the signature
    /// @param offChainUtility: Boolean to check if the utility is on-chain or off-chain
    /// @param signature: Signature to check above parameters
    function teenResurrect(
        uint256 utilityId,
        uint256 sacrificed,
        uint256 resurrected,
        uint256 timeOut,
        uint256 offChainUtility,
        bytes memory signature
    ) external {
        require(
            utilityId >= 30 && utilityId < 34,
            "teenResurrect: Wrong utilityId id"
        );
        require(
            timeOut > block.timestamp,
            "teenResurrect: Signature is expired"
        );
        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(
                        msg.sender,
                        utilityId,
                        sacrificed,
                        resurrected,
                        timeOut,
                        offChainUtility // 0 for on-chain, 1 for off-chain
                    )
                ),
                signature
            ),
            "teenResurrect: Signature is invalid"
        );
        require(
            !isResurrected[sacrificed],
            "teenResurrect: Can't sacrifice a resurrected Teen Bull"
        );
        require(
            !isResurrected[resurrected],
            "teenResurrect: Can't resurrect an already resurrected Teen Bull"
        );
        if (offChainUtility == 0) {
            masterContract.burn(utilityId, 1);
        } else {
            emit UtilityBurnedOffChain(msg.sender, utilityId, block.timestamp);
        }

        _burnTeen(sacrificed);

        isReviving = true;

        bapTeenBulls.airdrop(address(this), 1);

        isReviving = false;

        isResurrected[lastTokenReceived] = true;
        isResurrected[resurrected] = true;

        bapTeenBulls.safeTransferFrom(
            address(this),
            msg.sender,
            lastTokenReceived
        );

        emit TeenResurrected(
            msg.sender,
            sacrificed,
            resurrected,
            lastTokenReceived,
            offChainUtility
        );

        lastTokenReceived = 0;
    }

    /// @notice Handle the purchase of a Merger Orb
    /// @param teen: ID of the Teen Bull to sacrifice
    /// @dev Teen needs to be burned to be able to buy the Merger Orb
    function buyMergeOrb(uint256 teen) external {
        require(
            mergerOrbCounter < MERGER_ORB_AMOUNT,
            "buyMergeOrb: Merger Orbs sold out"
        );

        masterContract.pay(2400, 1200);

        _burnTeen(teen);

        masterContract.airdrop(msg.sender, 1, MERGER_ORB);

        mergerOrbCounter++;

        emit MergerOrbBought(msg.sender, block.timestamp);
    }

    /// @notice Handle the generation of Teen Bulls
    /// @dev Needs to pay METH and burn an Incubator
    function generateTeenBull() external {
        masterContract.pay(600, 300);
        masterContract.burn(1, 1);
        masterContract.airdrop(msg.sender, 1);
    }

    /// @notice Handle the purchase of a Merger Orb using off-chain payment or minting off-chain
    /// @param teen: ID of the Teen Bull to sacrifice
    /// @param timeOut: Time out for the signature
    /// @param offChainPayment: Boolean to check if the payment is on-chain or off-chain
    /// @param offChainMint: Boolean to check if the minting is on-chain or off-chain
    /// @param signature: Signature to check above parameters
    /// @dev If payment or mint is off-chain, emit the corresponding event
    function offChainMergeOrb(
        uint256 teen,
        uint256 timeOut,
        bool offChainPayment,
        bool offChainMint,
        bytes memory signature
    ) external {
        require(
            mergerOrbCounter < MERGER_ORB_AMOUNT,
            "offChainMergeOrb: Merger Orbs sold out"
        );
        require(
            timeOut > block.timestamp,
            "offChainMergeOrb: Signature is expired"
        );
        require(
            !usedSignatures[signature],
            "offChainMergeOrb: Signature already used"
        );
        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(msg.sender, teen, offChainPayment, offChainMint)
                ),
                signature
            ),
            "offChainMergeOrb: Signature is invalid"
        );

        usedSignatures[signature] = true;

        if (!offChainPayment) {
            masterContract.pay(2400, 1200);
        } else {
            emit OffChainMethPayment(msg.sender, 2400, block.timestamp);
        }

        _burnTeen(teen);

        if (!offChainMint) {
            masterContract.airdrop(msg.sender, 1, MERGER_ORB);

            emit MergerOrbBought(msg.sender, block.timestamp);
        } else {
            emit MergerOrbOffChainMint(msg.sender, block.timestamp);
        }

        mergerOrbCounter++;
    }

    /// @notice Handle the breeding replenishment using on-chain utilities
    /// @param utilityId: ID of the utility used to replenish
    /// @param tokenId: ID of the Bull to replenish
    /// @param signature: Signature to check above parameters
    /// @dev Only the owner of the Bull can replenish and God Bulls cannot claim extra breeding
    function replenishBreedings(
        uint256 utilityId,
        uint256 tokenId,
        bytes memory signature
    ) external {
        require(
            utilityId >= 40 && utilityId < 45,
            "replenishBreedings: Wrong utilityId id"
        );
        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, utilityId, tokenId)),
                signature
            ),
            "replenishBreedings: Signature is invalid"
        );
        require(
            bapGenesis.ownerOf(tokenId) == msg.sender,
            "replenishBreedings: Only the owner can replenish"
        );
        require(
            !godBulls(tokenId),
            "replenishBreedings: God bulls cannot claim extra breeding"
        );

        masterContract.burn(utilityId, 1);

        emit BreedingReplenish(msg.sender, tokenId, block.timestamp);
    }

    /// @notice Handle the burning of Utilities as deposit to be used off-chain
    /// @param utilityIds: IDs of the Utilities to burn
    /// @param amounts: Amounts to burn for each Utility
    function burnUtilities(
        uint256[] memory utilityIds,
        uint256[] memory amounts
    ) external {
        require(
            utilityIds.length == amounts.length,
            "burnUtilities: Arrays length mismatch"
        );

        for (uint256 i = 0; i < utilityIds.length; i++) {
            masterContract.burn(utilityIds[i], amounts[i]);
        }

        emit UtilityBurnedOnChain(
            msg.sender,
            utilityIds,
            amounts,
            block.timestamp
        );
    }

    /// @notice Handle the minting of Utilities held off-chain
    /// @param utilityIds: IDs of the Utilities to mint
    /// @param amounts: Amounts to mint for each Utility
    /// @param timeOut: Time out for the signature
    /// @param signature: Signature to check above parameters
    function mintUtilities(
        uint256[] memory utilityIds,
        uint256[] memory amounts,
        uint256 timeOut,
        bytes memory signature
    ) external {
        require(
            timeOut > block.timestamp,
            "mintUtilities: Signature is expired"
        );
        require(
            !usedSignatures[signature],
            "mintUtilities: Signature already used"
        );
        require(
            utilityIds.length == amounts.length,
            "mintUtilities: Arrays length mismatch"
        );

        usedSignatures[signature] = true;

        string memory mintCode;

        for (uint256 i = 0; i < utilityIds.length; i++) {
            mintCode = string.concat(mintCode, "ID", utilityIds[i].toString());
            mintCode = string.concat(mintCode, "A", amounts[i].toString());

            masterContract.airdrop(msg.sender, amounts[i], utilityIds[i]);
        }

        require(
            _verifyHashSignature(
                keccak256(abi.encode(msg.sender, mintCode, timeOut)),
                signature
            ),
            "mintUtilities: Signature is invalid"
        );

        emit UtilitiesMinted(msg.sender, utilityIds, amounts, block.timestamp);
    }

    /// @notice Handle the withdrawal from user's METH bank
    /// @param amount: Amount to withdraw
    /// @param timeOut: Time out for the signature
    /// @param signature: Signature to check above parameters
    function withdrawFromBank(
        uint256 amount,
        uint256 timeOut,
        bytes memory signature
    ) external {
        require(timeOut > block.timestamp, "withdrawFromBank: Signature is expired");
        require(!usedSignatures[signature], "withdrawFromBank: Signature already used");
        require(amount > 0, "withdrawFromBank: Amount must be greater than 0");        
        require(
            lastWithdraw[msg.sender] + withdrawCoolDown < block.timestamp,
            "withdrawFromBank: Withdrawal is too soon"
        );
        require(
            _verifyHashSignature(
                keccak256(abi.encode(amount, msg.sender, timeOut )),
                signature
            ),
            "withdrawFromBank: Signature is invalid"
        );

        usedSignatures[signature] = true;

        lastWithdraw[msg.sender] = block.timestamp;

        masterContract.claim(msg.sender, amount);

        emit MethWithdrawn(msg.sender, amount, signature, block.timestamp);
    }

    /// @notice Internal function to burn a Teen Bull
    /// @param tokenId: ID of the Teen Bull to burn
    /// @dev Only the owner of the Teen Bull can burn it and resurrected Teen Bulls cannot be burned
    function _burnTeen(uint256 tokenId) internal {
        require(
            bapTeenBulls.ownerOf(tokenId) == msg.sender,
            "Only the owner can burn"
        );
        require(!isResurrected[tokenId], "Can't burn resurrected teens");

        bapTeenBulls.burnTeenBull(tokenId);
    }

    /// @notice Internal function to set isResurrected status on previously resurrected Teen Bulls
    /// @param tokenIds: Array of Teen Bull IDs to set isResurrected status
    /// @param boolean: Boolean to set isResurrected status
    /// @dev Only used to set isResurrected status on Teen Bulls resurrected before the contract deployment
    function setIsResurrected(
        uint256[] memory tokenIds,
        bool boolean
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            isResurrected[tokenIds[i]] = boolean;
        }
    }

    /// @notice Internal function to set a new signer
    /// @param newSigner: Address of the new signer
    /// @dev Only the owner can set a new signer
    function setSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "Invalid address");
        secret = newSigner;
    }

    /// @notice Internal function to set the withdraw cool down
    /// @param newCoolDown: New withdraw cool down
    /// @dev Only the owner can set the withdraw cool down
    function setWithdrawCoolDown(uint256 newCoolDown) external onlyOwner {
        withdrawCoolDown = newCoolDown;
    }

    /// @notice Internal function to check if a Bull is a God Bull
    /// @param tokenId: ID of the Bull to check
    function godBulls(uint256 tokenId) internal view returns (bool) {
        return tokenId > 10010 || isGod[tokenId];
    }

    /// @notice Internal function to handle the transfer of a Teen Bull during the resurrection process
    /// @param tokenId: ID of the Teen Bull to transfer
    /// @dev Only accept transfers from BAP Teens and only while reviving
    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes memory
    ) external virtual override returns (bytes4) {
        require(
            msg.sender == address(bapTeenBulls),
            "Only receive from BAP Teens"
        );
        require(isReviving, "Only accept transfers while reviving");
        lastTokenReceived = tokenId;
        return this.onERC721Received.selector;
    }

    /// @notice Transfer ownership from external contracts owned by this contract
    /// @param _contract Address of the external contract
    /// @param _newOwner New owner
    /// @dev Only contract owner can call this function
    function transferOwnershipExternalContract(
        address _contract,
        address _newOwner
    ) external onlyOwner {
        Ownable(_contract).transferOwnership(_newOwner);
    }

    /// @notice Internal function to check if a signature is valid
    /// @param freshHash: Hash to check
    /// @param signature: Signature to check
    function _verifyHashSignature(
        bytes32 freshHash,
        bytes memory signature
    ) internal view returns (bool) {
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