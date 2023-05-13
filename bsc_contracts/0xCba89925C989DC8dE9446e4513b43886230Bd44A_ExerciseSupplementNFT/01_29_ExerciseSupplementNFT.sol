// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./EnumerableSet.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IChallenge.sol";
import "./AccessControlUpgradeable.sol";

contract ExerciseSupplementNFT is
    Initializable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{   
    /**
     * Importing Solidity libraries
     * The Strings library provides a way to concatenate strings with other types
     * The SafeMath library provides safe arithmetic operations to prevent overflow and underflow errors
     * The Counters library provides a way to generate unique sequential IDs
     * The EnumerableSet library provides a set data structure to store and manipulate data
     */
    using StringsUpgradeable for uint256;
    using SafeMath for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @dev This struct defines the special conditions for NFT challenges.
     *
     * @param targetStepPerDay The number of steps a user must achieve daily to complete the challenge.
     * @param challengeDuration The duration of the challenge, in seconds.
     * @param amountDepositMatic The deposit amount in Matic token required to participate in the challenge.
     * @param amountDepositTTJP The deposit amount in TTJP token required to participate in the challenge.
     * @param amountDepositJPYC The deposit amount in JPYC token required to participate in the challenge.
     * @param dividendSuccess The percentage of the deposit amount that successful participants will receive as a dividend.
     */
    struct NftSpecialConditionInfo {
        uint256 targetStepPerDay;
        uint256 challengeDuration;
        uint256 amountDepositMatic;
        uint256 amountDepositTTJP;
        uint256 amountDepositJPYC;
        uint256 dividendSuccess;
    }

    CountersUpgradeable.Counter private _tokenIdCounter; // Counter for tracking token IDs

    string public baseURI; // Base URI for token metadata

    string private baseExtension; // Extension for token metadata files

    EnumerableSet.AddressSet private listNftAddress; // Set of addresses for non-fungible tokens

    EnumerableSet.AddressSet private listERC20Address; // Set of addresses for ERC20 tokens

    EnumerableSet.AddressSet private listSpecialNftAddress; // Set of addresses for special non-fungible tokens

    EnumerableSet.AddressSet private gachaContractAddress; // Set of addresses for gacha contracts

    address public donationWalletAddress; // Address for donation wallet

    address public feeSettingAddress; // Address fee setting

    address public returnedNFTWallet; // Returned NFT wallet

    mapping(address => bool) public typeNfts; // Mapping of token types to boolean values

    NftSpecialConditionInfo public listNftSpecialConditionInfo; // Struct containing special conditions for non-fungible tokens

    mapping(address => uint256) private typeTokenErc20; // Mapping of ERC20 token types to token IDs

    uint256[] private listToleranceAmount; // Set of tolerance amounts for token balances

    mapping(uint256 => mapping(address => address)) private _historySendNFT; // Mapping from id to address contract to sender address

    uint256[] private sizeContract; // Size of the contract

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE"); // Define the role that can upgrade the contract

    bytes32 public constant UPDATER_ACTIVITIES_ROLE =
        keccak256("UPDATER_ACTIVITIES_ROLE"); // Define the role that can update contract activities

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // Define the role that can mint new NFTs

    /**
     * @dev Modifier to check if the given address is allowed to mint NFTs.
     * @param _address The address to check.
     */
    modifier isAllowToMintNft(address _address, uint256 logicSize) {
        require(_address.code.length == logicSize, "NOT ALLOW TO MINT NFT");
        _;
    }

    /**
     * @dev Initializes the contract by setting the base URI, initializing the inherited ERC721, ERC721Burnable,
     * UUPSUpgradeable contracts, granting roles, and setting the base extension and size of the contract.
     * @param _initBaseURI the initial base URI for the NFT
     * @param _sizeContract the size of the contract
     */
    function initialize(
        string memory _initBaseURI,
        uint256[] memory _sizeContract,
        address _donationWalletAddress,
        address _feeSettingAddress,
        address _returnedNFTWallet
    ) public initializer {
        __ERC721_init("ExerciseSupplementNFT", "ESPLNFT");
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, address(this));
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(UPDATER_ACTIVITIES_ROLE, msg.sender);

        baseExtension = ".json";
        sizeContract = _sizeContract;
        baseURI = _initBaseURI;
        donationWalletAddress = _donationWalletAddress;
        feeSettingAddress = _feeSettingAddress;
        returnedNFTWallet = _returnedNFTWallet;
    }

    /**
     * @dev Mint a new NFT to the specified address.
     * @param to The address to receive the newly minted NFT.
     */
    function safeMint(address to) public payable onlyRole(MINTER_ROLE) {
        // get the next available token ID
        uint256 tokenId = _tokenIdCounter.current();
        // increment the token ID counter
        _tokenIdCounter.increment();
        // mint the new NFT to the specified address
        _safeMint(to, tokenId);
    }

    /**
     * @dev Set the base URI for all tokens.
     * @param _newBaseURI The new base URI to set.
     */
    function setBaseURI(
        string memory _newBaseURI
    ) public onlyRole(UPDATER_ACTIVITIES_ROLE) {
        // Update the base URI with the new URI provided by the owner
        baseURI = _newBaseURI;
    }

    /**
     * @dev Updates the base extension for the token URI.
     * @param _newBaseExtension The new base extension to set.
     */
    function setBaseExtension(
        string memory _newBaseExtension
    ) public onlyRole(UPDATER_ACTIVITIES_ROLE) {
        // Update the base extension with the new extension provided by the owner
        baseExtension = _newBaseExtension;
    }

    /**
     * @dev Update the tolerance amount for trade matching.
     * @param _toleranceAmount The new tolerance amount to set.
     * @param _flag A flag indicating whether to add or remove the tolerance amount from the list.
     */
    function updateToleranceAmount(
        uint256 _toleranceAmount,
        bool _flag
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        // Check if the tolerance amount is valid
        require(_toleranceAmount > 0, "INVALID TOLERANCE AMOUNT");

        // Add or remove the tolerance amount from the list based on the flag
        if (_flag) {
            require(
                listToleranceAmount.length < 2,
                "TOLERANCE AMOUNT LIST IS ALREADY FULL"
            );
            listToleranceAmount.push(_toleranceAmount);
        } else {
            require(
                listToleranceAmount.length > 0,
                "TOLERANCE AMOUNT LIST IS EMPTY"
            );
            for (uint256 i = 0; i < listToleranceAmount.length; i++) {
                if (listToleranceAmount[i] == _toleranceAmount) {
                    listToleranceAmount[i] = listToleranceAmount[
                        listToleranceAmount.length - 1
                    ];
                    listToleranceAmount.pop();
                    break;
                }
            }
        }
    }

    /**
     * @dev Update the list of NFT contract addresses.
     * @param _nftAddress The NFT contract address to add or remove from the list.
     * @param _flag A boolean indicating whether to add or remove the NFT contract address from the list.
     * @param _isTypeErc721 A boolean indicating whether the NFT contract is of type ERC721 or not.
     */
    function updateNftListAddress(
        address _nftAddress,
        bool _flag,
        bool _isTypeErc721
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(_nftAddress != address(0), "INVALID NFT ADDRESS");
        if (_flag) {
            listNftAddress.add(_nftAddress);
        } else {
            listNftAddress.remove(_nftAddress);
        }
        typeNfts[_nftAddress] = _isTypeErc721;
    }

    /**
     * @dev Update the list of ERC20 token addresses and sets their type based on their symbol.
     * @param _erc20Address The address of the ERC20 token to add or remove from the list.
     * @param _flag A boolean indicating whether to add or remove the token from the list.
     */
    function updateListERC20Address(
        address _erc20Address,
        bool _flag
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(_erc20Address != address(0), "INVALID NFT ADDRESS");
        if (_flag) {
            listERC20Address.add(_erc20Address);
        } else {
            listERC20Address.remove(_erc20Address);
        }
        // Sets the type of ERC20 token based on its symbol
        if (compareStrings(ERC721Upgradeable(_erc20Address).symbol(), "TTJP")) {
            typeTokenErc20[_erc20Address] = 1;
        } else {
            if (
                compareStrings(
                    ERC721Upgradeable(_erc20Address).symbol(),
                    "JPYC"
                )
            ) {
                typeTokenErc20[_erc20Address] = 2;
            } else {
                typeTokenErc20[_erc20Address] = 3;
            }
        }
    }

    /**
     * @dev Update the special NFT address.
     * @param _nftAddress The new special NFT address to set.
     * @param _flag Boolean flag to indicate whether to add or remove the special NFT address.
     */
    function updateSpecialNftAddress(
        address _nftAddress,
        bool _flag
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(_nftAddress != address(0), "INVALID ADDRESS");
        if (_flag) {
            listSpecialNftAddress.add(_nftAddress);
        } else {
            listSpecialNftAddress.remove(_nftAddress);
        }
    }

    /**
     * @dev Update the donation wallet address.
     * @param _donationWalletAddress The new donation wallet address to set.
     */
    function updateDonationWalletAddress(
        address _donationWalletAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _donationWalletAddress != address(0),
            "INVALID DONATION WALLET ADDRESS"
        );
        donationWalletAddress = _donationWalletAddress;
    }

    /**
     * @dev Update the address of the fee setting contract.
     * @param _feeSettingAddress The new fee setting contract address.
     */
    function updateFeeSettingAddress(
        address _feeSettingAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _feeSettingAddress != address(0),
            "INVALID FEE SETTING ADDRESS"
        );
        feeSettingAddress = _feeSettingAddress;
    }

    /**
     * @dev Update the address of the wallet where returned NFTs should be sent.
     * @param _returnedNFTWallet The new address of the returned NFT wallet.
     */
    function updateReturnedNFTWallet(
        address _returnedNFTWallet
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _returnedNFTWallet != address(0),
            "RETURNED NFT WALLET IS NOT INVALID"
        );
        returnedNFTWallet = _returnedNFTWallet;
    }

    /**
     * @dev Removes or adds a gacha contract address from/to the list of registered gacha contracts.
     * @param _gachaContractAddress The address of the gacha contract to add/remove.
     * @param _flag A boolean indicating whether to add or remove the contract address.
     */
    function updateGachaContractAddress(
        address _gachaContractAddress,
        bool _flag
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(
            _gachaContractAddress != address(0),
            "INVALID GACHA CONTRACT ADDRESS."
        );
        if (_flag) {
            gachaContractAddress.add(_gachaContractAddress);
        } else {
            gachaContractAddress.remove(_gachaContractAddress);
        }
    }

    /**
     * @dev Sets the maximum size of the contract in bytes.
     * @param _sizeCodeContract Maximum size of the contract in bytes.
     * @notice Only the admin can call this function.
     * @notice The size of the contract should be greater than zero.
     */
    function setSizeContract(
        uint256[] memory _sizeCodeContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _sizeCodeContract.length > 0,
            "SIZE CONTRACT MUST BE GREAT THEN ZERO"
        );
        sizeContract = _sizeCodeContract;
    }

    /**
     * @dev Update the special condition information for the NFT.
     * @param targetStepPerDay The target step count per day for the challenge.
     * @param challengeDuration The duration of the challenge in days.
     * @param amountDepositMatic The deposit amount in MATIC.
     * @param amountDepositTTJP The deposit amount in TTJP token.
     * @param amountDepositJPYC The deposit amount in JPYC token.
     * @param dividendSuccess The dividend percentage for successful challenge completion.
     */
    function updateSpecialConditionInfo(
        uint256 targetStepPerDay,
        uint256 challengeDuration,
        uint256 amountDepositMatic,
        uint256 amountDepositTTJP,
        uint256 amountDepositJPYC,
        uint256 dividendSuccess
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        // Update the special condition information for the NFT.
        listNftSpecialConditionInfo = NftSpecialConditionInfo(
            targetStepPerDay,
            challengeDuration,
            amountDepositMatic,
            amountDepositTTJP,
            amountDepositJPYC,
            dividendSuccess
        );
    }

    /**
     * @dev Safely mints an NFT721 token to the specified address.
     * @param _tokenAddress The address of the NFT721 contract to mint the token from.
     * @param _challengerAddress The address to mint the NFT721 token to.
     */
    function safeMintNFT721Heper(
        address _tokenAddress,
        address _challengerAddress
    ) public isAllowToMintNft(msg.sender, sizeContract[1]) {
        TransferHelper.safeMintNFT(_tokenAddress, _challengerAddress);
    }

    /**
     * @dev Safely mints an NFT1155 token to the specified address.
     * @param _tokenAddress The address of the NFT1155 contract.
     * @param _challengerAddress The address to mint the NFT1155 token to.
     * @param _indexToken The index of the NFT1155 token to mint.
     * @param _rewardToken The amount of the NFT1155 token to mint.
     * Note: the _rewardToken parameter is used to indicate the amount of the token to be minted.
     * @notice This function uses the TransferHelper contract to safely mint the NFT1155 token to the specified address.
     * It also encodes the _challengerAddress, _indexToken, and _rewardToken parameters into extraData to be used in the onERC1155Received function
     * of the recipient contract (if it exists).
     */
    function safeMintNFT1155Heper(
        address _tokenAddress,
        address _challengerAddress,
        uint256 _indexToken,
        uint256 _rewardToken
    ) public isAllowToMintNft(msg.sender, sizeContract[1]) {
        // Encode data transfer token
        bytes memory extraData = abi.encode(
            _challengerAddress,
            _indexToken,
            _rewardToken
        );

        TransferHelper.safeMintNFT1155(
            _tokenAddress,
            _challengerAddress,
            _indexToken,
            _rewardToken,
            extraData
        );
    }

    /**
     * @dev Function to mint an NFT based on certain conditions and return the address and index of the minted NFT.
     * @param _goal The goal number of steps for the challenge.
     * @param _duration The duration of the challenge in days.
     * @param _dayRequired The number of days required to complete the challenge.
     * @param _createByToken The address of the token used to create the challenge.
     * @param _totalReward The total reward amount for the challenge.
     * @param _awardReceiversPercent The percentage of the reward that will go to the award receivers.
     * @param _awardReceivers The address of the award receivers.
     * @param _challenger The address of the challenger who will receive the NFT.
     * @return The address and index of the minted NFT.
     */
    function safeMintNFT(
        uint256 _goal,
        uint256 _duration,
        uint256 _dayRequired,
        address _createByToken,
        uint256 _totalReward,
        uint256 _awardReceiversPercent,
        address _awardReceivers,
        address _challenger
    )
        public
        isAllowToMintNft(msg.sender, sizeContract[0])
        returns (address, uint256)
    {
        address curentAddressNftUse; // The address of the NFT that will be used.
        uint256 indexNftAfterMint; // The index of the NFT after it is minted.

        // Check if the conditions for minting a special NFT are met.
        if (
            _goal >= listNftSpecialConditionInfo.targetStepPerDay &&
            _duration >= listNftSpecialConditionInfo.challengeDuration &&
            checkAmountDepositCondition(_createByToken, _totalReward)
        ) {
            // Check if the conditions for minting the second special NFT are met.
            if (
                _awardReceiversPercent ==
                listNftSpecialConditionInfo.dividendSuccess &&
                _awardReceivers == donationWalletAddress &&
                _dayRequired >=
                _duration.sub(_duration.div(listToleranceAmount[1]))
            ) {
                safeMintNFT721Heper(listSpecialNftAddress.at(1), _challenger);
                curentAddressNftUse = listSpecialNftAddress.at(1);
                indexNftAfterMint = ExerciseSupplementNFT(
                    listSpecialNftAddress.at(1)
                ).nextTokenIdToMint();
            } else {
                // Check if the conditions for minting the first special NFT are met.
                if (
                    _dayRequired >=
                    _duration.sub(_duration.div(listToleranceAmount[0]))
                ) {
                    safeMintNFT721Heper(
                        listSpecialNftAddress.at(0),
                        _challenger
                    );
                    curentAddressNftUse = listSpecialNftAddress.at(0);
                    indexNftAfterMint = ExerciseSupplementNFT(
                        listSpecialNftAddress.at(0)
                    ).nextTokenIdToMint();
                }
            }
        } else {
            // Mint a regular NFT if the conditions for minting a special NFT are not met.
            safeMintNFT721Heper(listNftAddress.at(0), _challenger);
            curentAddressNftUse = listNftAddress.at(0);
            indexNftAfterMint = ExerciseSupplementNFT(listNftAddress.at(0))
                .nextTokenIdToMint();
        }

        return (curentAddressNftUse, indexNftAfterMint);
    }

    /**
     * @dev Checks the conditions for the amount of deposit required for creating special NFTs.
     * If the token type is not specified and the total reward is greater than or equal to the required deposit amount in Matic, returns true.
     * If the token type is not specified, returns false.
     * If the token type is specified and the total reward is greater than or equal to the required deposit amount in TTJP or JPYC, returns true.
     * @param _createByToken The address of the token used to create the NFT. If not specified, it is the zero address.
     * @param _totalReward The total reward amount for creating the NFT.
     * @return bool Returns true if the amount of deposit required is met, otherwise false.
     */
    function checkAmountDepositCondition(
        address _createByToken,
        uint256 _totalReward
    ) private view returns (bool) {
        // If the token type is not specified and the total reward is greater than or equal to the required deposit amount in Matic
        if (
            _createByToken == address(0) &&
            _totalReward >= listNftSpecialConditionInfo.amountDepositMatic
        ) {
            return true;
        }

        // If the token type is not specified
        if (_createByToken == address(0)) {
            return false;
        }

        // If the token type is specified and the total reward is greater than or equal to the required deposit amount in TTJP or JPYC
        if (
            (typeTokenErc20[_createByToken] == 1 &&
                _totalReward >=
                listNftSpecialConditionInfo.amountDepositTTJP) ||
            (typeTokenErc20[_createByToken] == 2 &&
                _totalReward >= listNftSpecialConditionInfo.amountDepositJPYC)
        ) {
            return true;
        }

        return false;
    }

    /**
     * @dev Returns an array of all NFT contracts' addresses currently supported by the NFTMarketplace contract.
     * @return An array of all NFT contracts' addresses currently supported by the NFTMarketplace contract.
     */
    function getNftListAddress() external view returns (address[] memory) {
        return listNftAddress.values();
    }

    /**
     * @dev Returns an array of ERC20 token addresses that are accepted by the contract.
     * @return An array of ERC20 token addresses.
     */
    function getErc20ListAddress() external view returns (address[] memory) {
        return listERC20Address.values();
    }

    /**
     * @dev Returns an array of addresses of the special NFT contracts.
     * @return An array of addresses of the special NFT contracts.
     */
    function getSpecialNftAddress() external view returns (address[] memory) {
        return listSpecialNftAddress.values();
    }

    /**
     * @dev Returns an array of all the addresses that represent Gacha contracts.
     * This function returns an array of all the registered addresses that represent Gacha contracts.
     * It uses the `values` function of the `EnumerableSet` library to get the values stored in `gachaContractAddress`.
     * @return An array of all the addresses that represent Gacha contracts.
     */
    function getListGachaAddress() public view returns (address[] memory) {
        return gachaContractAddress.values();
    }

    /**
     * @dev Compares two strings and returns a boolean indicating if they are equal.
     * @param a The first string to compare.
     * @param b The second string to compare.
     * @return bool Returns true if the strings are equal, otherwise false.
     */
    function compareStrings(
        string memory a,
        string memory b
    ) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    /**
     * @dev Returns the current value of the `_tokenIdCounter`, which is an instance of the `Counters` contract from the OpenZeppelin library.
     * The `_tokenIdCounter` is used to keep track of the token ID of the next NFT to be minted.
     */
    function nextTokenIdToMint() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Get the list of tolerance amounts stored in the data structure listToleranceAmount.
     * @return An array of uint256 values representing the list of tolerance amounts.
     */
    function getListToleranceAmount() external view returns (uint256[] memory) {
        return listToleranceAmount;
    }

    /**
     * @dev Get the type of the ERC20 token at a specific address.
     * @param _erc20Address The address of the ERC20 token to query.
     * @return The type of the ERC20 token (0 for unknown, 1 for MTK, 2 for USDT, etc.).
     */
    function getTypeTokenErc20(
        address _erc20Address
    ) public view returns (uint256) {
        return typeTokenErc20[_erc20Address];
    }

    /**
     * @dev Get the address of the last recipient of the specified NFT token and the address of the sender who sent the NFT to the recipient.
     * @param tokenId The ID of the NFT token to query.
     * @param to The address of the last recipient to query.
     * @return The address of the sender who sent the NFT to the recipient.
     */
    function getHistoryNFT(
        uint256 tokenId,
        address to
    ) public view returns (address) {
        return _historySendNFT[tokenId][to];
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *
     * Reverts if the token ID does not exist.
     *
     * The URI can be a simple sequence of bytes (eg. an HTTP or IPFS URL), or
     * a more structured data like JSON metadata, depending on the deployment.
     *
     * Requirements:
     * - `tokenId` must exist.
     *
     * @param tokenId uint256 ID of the token to query
     * @return string memory URI of the token
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        // Check if the given token ID exists
        require(
            _exists(tokenId),
            "ERC721METADATA: URI QUERY FOR NONEXISTENT TOKEN"
        );

        // Get the base URI and concatenate it with the token ID and base extension to form the final URI
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
     * @dev Returns the base URI for all tokens of this contract. This method is an override of the OpenZeppelin _baseURI method,
     * which is used to specify a base URI for all tokens in the contract.
     * @return string A string representing the base URI for all tokens of this contract.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        // return the current base URI for the NFT
        return baseURI;
    }

    /**
     * @dev Internal function to authorize the upgrade of the contract implementation.
     * @param newImplementation Address of the new implementation contract.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev Hook function called before any token transfer, including minting and burning.
     * This function sets the history of transfers for the first token ID in the batch.
     * @param from The address tokens are transferred from.
     * @param to The address tokens are transferred to.
     * @param firstTokenId The ID of the first token in the batch.
     * @param batchSize The number of tokens in the batch.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        // Set history transfer token
        if (to != address(0) && from != address(0) && batchSize >= 0) {
            uint256 size;
            assembly {
                size := extcodesize(to)
            }
            if (size > 0) {
                _historySendNFT[firstTokenId][to] = from;
            }

            if (size == sizeContract[0]) {
                require(
                    !IChallenge(payable(to)).isFinished(),
                    "ERC721: CHALLENGE WAS FINISHED"
                );
            }
        }
    }

    /**
     * @dev Returns whether the contract supports a given interface.
     * Implements ERC165 and AccessControl interfaces.
     * @param interfaceId The interface identifier, as specified in ERC-165 and AccessControl.
     * @return True if the contract supports `interfaceId`, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
