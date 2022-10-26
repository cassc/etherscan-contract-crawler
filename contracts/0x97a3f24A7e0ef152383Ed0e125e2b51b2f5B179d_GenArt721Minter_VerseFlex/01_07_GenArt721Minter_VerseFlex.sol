// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../../interfaces/0.8.x/IGenArt721CoreV2_PBAB.sol";
import "../../interfaces/0.8.x/IBonusContract.sol";

import "@openzeppelin-4.5/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin-4.5/contracts/utils/Strings.sol";
import "@openzeppelin-4.5/contracts/interfaces/IERC20.sol";

pragma solidity 0.8.9;

/**
 * @title Powered by Art Blocks minter contract that allows tokens to be
 * minted with ETH or any ERC-20 token.
 * @author Art Blocks Inc.
 */
contract GenArt721Minter_VerseFlex is ReentrancyGuard {
    /// PBAB core contract this minter may interact with.
    IGenArt721CoreV2_PBAB public genArtCoreContract;

    uint256 constant ONE_MILLION = 1_000_000;

    address payable public ownerAddress;
    uint256 public ownerPercentage;

    mapping(uint256 => bool) public projectIdToBonus;
    mapping(uint256 => address) public projectIdToBonusContractAddress;
    mapping(uint256 => bool) public contractFilterProject;
    mapping(address => mapping(uint256 => uint256)) public projectMintCounter;
    mapping(uint256 => uint256) public projectMintLimit;
    mapping(uint256 => bool) public projectMaxHasBeenInvoked;
    mapping(uint256 => uint256) public projectMaxInvocations;

    /**
     * @notice Initializes contract to be a Minter for PBAB core contract at
     * address `_genArt721Address`.
     */
    constructor(address _genArt721Address) ReentrancyGuard() {
        genArtCoreContract = IGenArt721CoreV2_PBAB(_genArt721Address);
    }

    /**
     * @notice Gets your balance of the ERC-20 token currently set
     * as the payment currency for project `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return balance Balance of ERC-20
     */
    function getYourBalanceOfProjectERC20(uint256 _projectId)
        public
        view
        returns (uint256)
    {
        uint256 balance = IERC20(
            genArtCoreContract.projectIdToCurrencyAddress(_projectId)
        ).balanceOf(msg.sender);
        return balance;
    }

    /**
     * @notice Gets your allowance for this minter of the ERC-20
     * token currently set as the payment currency for project
     * `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return remaining Remaining allowance of ERC-20
     */
    function checkYourAllowanceOfProjectERC20(uint256 _projectId)
        public
        view
        returns (uint256)
    {
        uint256 remaining = IERC20(
            genArtCoreContract.projectIdToCurrencyAddress(_projectId)
        ).allowance(msg.sender, address(this));
        return remaining;
    }

    /**
     * @notice Sets the mint limit of a single purchaser for project
     * `_projectId` to `_limit`.
     * @param _projectId Project ID to set the mint limit for.
     * @param _limit Number of times a given address may mint the project's
     * tokens.
     */
    function setProjectMintLimit(uint256 _projectId, uint8 _limit) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        projectMintLimit[_projectId] = _limit;
    }

    /**
     * @notice Sets the maximum invocations of project `_projectId` based
     * on the value currently defined in the core contract.
     * @param _projectId Project ID to set the maximum invocations for.
     * @dev also checks and may refresh projectMaxHasBeenInvoked for project
     */
    function setProjectMaxInvocations(uint256 _projectId) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        uint256 maxInvocations;
        uint256 invocations;
        (, , invocations, maxInvocations, , , , , ) = genArtCoreContract
            .projectTokenInfo(_projectId);
        projectMaxInvocations[_projectId] = maxInvocations;
        if (invocations < maxInvocations) {
            projectMaxHasBeenInvoked[_projectId] = false;
        }
    }

    /**
     * @notice Sets the owner address to `_ownerAddress`.
     * @param _ownerAddress New owner address.
     */
    function setOwnerAddress(address payable _ownerAddress) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        ownerAddress = _ownerAddress;
    }

    /**
     * @notice Sets the owner mint revenue to `_ownerPercentage` percent.
     * @param _ownerPercentage New owner percentage.
     */
    function setOwnerPercentage(uint256 _ownerPercentage) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        ownerPercentage = _ownerPercentage;
    }

    /**
     * @notice Toggles if contracts are allowed to mint tokens for
     * project `_projectId`.
     * @param _projectId Project ID to be toggled.
     */
    function toggleContractFilter(uint256 _projectId) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        contractFilterProject[_projectId] = !contractFilterProject[_projectId];
    }

    /**
     * @notice Toggles if bonus contract for project `_projectId`.
     * @param _projectId Project ID to be toggled.
     */
    function artistToggleBonus(uint256 _projectId) public {
        require(
            msg.sender ==
                genArtCoreContract.projectIdToArtistAddress(_projectId),
            "can only be set by artist"
        );
        projectIdToBonus[_projectId] = !projectIdToBonus[_projectId];
    }

    /**
     * @notice Sets bonus contract for project `_projectId` to
     * `_bonusContractAddress`.
     * @param _projectId Project ID to be toggled.
     * @param _bonusContractAddress Bonus contract.
     */
    function artistSetBonusContractAddress(
        uint256 _projectId,
        address _bonusContractAddress
    ) public {
        require(
            msg.sender ==
                genArtCoreContract.projectIdToArtistAddress(_projectId),
            "can only be set by artist"
        );
        projectIdToBonusContractAddress[_projectId] = _bonusContractAddress;
    }

    /**
     * @notice Purchases a token from project `_projectId`.
     * @param _projectId Project ID to mint a token on.
     * @return _tokenId Token ID of minted token
     */
    function purchase(uint256 _projectId)
        public
        payable
        returns (uint256 _tokenId)
    {
        return purchaseTo(msg.sender, _projectId);
    }

    /**
     * @notice Purchases a token from project `_projectId` and sets
     * the token's owner to `_to`.
     * @param _to Address to be the new token's owner.
     * @param _projectId Project ID to mint a token on.
     * @return _tokenId Token ID of minted token
     */
    function purchaseTo(address _to, uint256 _projectId)
        public
        payable
        nonReentrant
        returns (uint256 _tokenId)
    {
        // CHECKS
        require(
            !projectMaxHasBeenInvoked[_projectId],
            "Maximum number of invocations reached"
        );
        // if contract filter is active prevent calls from another contract
        if (contractFilterProject[_projectId]) {
            require(msg.sender == tx.origin, "No Contract Buys");
        }

        // limit mints per address by project
        if (projectMintLimit[_projectId] > 0) {
            require(
                projectMintCounter[msg.sender][_projectId] <
                    projectMintLimit[_projectId],
                "Reached minting limit"
            );
            // EFFECTS
            projectMintCounter[msg.sender][_projectId]++;
        }

        uint256 tokenId = genArtCoreContract.mint(_to, _projectId, msg.sender);

        // What if this overflows, since default value of uint256 is 0?
        // That is intended, so that by default the minter allows infinite
        // transactions, allowing the `genArtCoreContract` to stop minting
        // `uint256 tokenInvocation = tokenId % ONE_MILLION;`
        if (
            projectMaxInvocations[_projectId] > 0 &&
            tokenId % ONE_MILLION == projectMaxInvocations[_projectId] - 1
        ) {
            projectMaxHasBeenInvoked[_projectId] = true;
        }

        // INTERACTIONS
        // bonus contract
        if (projectIdToBonus[_projectId]) {
            require(
                IBonusContract(projectIdToBonusContractAddress[_projectId])
                    .bonusIsActive(),
                "bonus must be active"
            );
            IBonusContract(projectIdToBonusContractAddress[_projectId])
                .triggerBonus(msg.sender);
        }

        // validate and split funds
        if (
            keccak256(
                abi.encodePacked(
                    genArtCoreContract.projectIdToCurrencySymbol(_projectId)
                )
            ) != keccak256(abi.encodePacked("ETH"))
        ) {
            require(
                msg.value == 0,
                "this project accepts a different currency and cannot accept ETH"
            );
            require(
                IERC20(
                    genArtCoreContract.projectIdToCurrencyAddress(_projectId)
                ).allowance(msg.sender, address(this)) >=
                    genArtCoreContract.projectIdToPricePerTokenInWei(
                        _projectId
                    ),
                "Insufficient Funds Approved for TX"
            );
            require(
                IERC20(
                    genArtCoreContract.projectIdToCurrencyAddress(_projectId)
                ).balanceOf(msg.sender) >=
                    genArtCoreContract.projectIdToPricePerTokenInWei(
                        _projectId
                    ),
                "Insufficient balance."
            );
            _splitFundsERC20(_projectId);
        } else {
            require(
                msg.value >=
                    genArtCoreContract.projectIdToPricePerTokenInWei(
                        _projectId
                    ),
                "Must send minimum value to mint!"
            );
            _splitFundsETH(_projectId);
        }

        return tokenId;
    }

    /**
     * @dev splits ETH funds between sender (if refund), foundation,
     * artist, and artist's additional payee for a token purchased on
     * project `_projectId`.
     * @dev utilizes transfer() to send ETH, so access lists may need to be
     * populated when purchasing tokens.
     */
    function _splitFundsETH(uint256 _projectId) internal {
        if (msg.value > 0) {
            uint256 pricePerTokenInWei = genArtCoreContract
                .projectIdToPricePerTokenInWei(_projectId);
            uint256 refund = msg.value -
                genArtCoreContract.projectIdToPricePerTokenInWei(_projectId);
            if (refund > 0) {
                (bool success_, ) = msg.sender.call{value: refund}("");
                require(success_, "Refund failed");
            }
            uint256 renderProviderAmount = (pricePerTokenInWei *
                genArtCoreContract.renderProviderPercentage()) / 100;
            if (renderProviderAmount > 0) {
                (bool success_, ) = genArtCoreContract
                    .renderProviderAddress()
                    .call{value: renderProviderAmount}("");
                require(success_, "Renderer payment failed");
            }

            uint256 remainingFunds = pricePerTokenInWei - renderProviderAmount;

            uint256 ownerFunds = (remainingFunds * ownerPercentage) / 100;
            if (ownerFunds > 0) {
                (bool success_, ) = ownerAddress.call{value: ownerFunds}("");
                require(success_, "Owner payment failed");
            }

            uint256 projectFunds = pricePerTokenInWei -
                renderProviderAmount -
                ownerFunds;
            uint256 additionalPayeeAmount;
            if (
                genArtCoreContract.projectIdToAdditionalPayeePercentage(
                    _projectId
                ) > 0
            ) {
                additionalPayeeAmount =
                    (projectFunds *
                        genArtCoreContract.projectIdToAdditionalPayeePercentage(
                            _projectId
                        )) /
                    100;
                if (additionalPayeeAmount > 0) {
                    (bool success_, ) = genArtCoreContract
                        .projectIdToAdditionalPayee(_projectId)
                        .call{value: additionalPayeeAmount}("");
                    require(success_, "Additional payment failed");
                }
            }
            uint256 creatorFunds = projectFunds - additionalPayeeAmount;
            if (creatorFunds > 0) {
                (bool success_, ) = genArtCoreContract
                    .projectIdToArtistAddress(_projectId)
                    .call{value: creatorFunds}("");
                require(success_, "Artist payment failed");
            }
        }
    }

    /**
     * @dev splits ERC-20 funds between render provider, owner, artist, and
     * artist's additional payee, for a token purchased on project
     `_projectId`.
     */
    function _splitFundsERC20(uint256 _projectId) internal {
        uint256 pricePerTokenInWei = genArtCoreContract
            .projectIdToPricePerTokenInWei(_projectId);
        uint256 renderProviderAmount = (pricePerTokenInWei *
            genArtCoreContract.renderProviderPercentage()) / 100;
        if (renderProviderAmount > 0) {
            IERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId))
                .transferFrom(
                    msg.sender,
                    genArtCoreContract.renderProviderAddress(),
                    renderProviderAmount
                );
        }
        uint256 remainingFunds = pricePerTokenInWei - renderProviderAmount;

        uint256 ownerFunds = (remainingFunds * ownerPercentage) / 100;
        if (ownerFunds > 0) {
            IERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId))
                .transferFrom(msg.sender, ownerAddress, ownerFunds);
        }

        uint256 projectFunds = pricePerTokenInWei -
            renderProviderAmount -
            ownerFunds;
        uint256 additionalPayeeAmount;
        if (
            genArtCoreContract.projectIdToAdditionalPayeePercentage(
                _projectId
            ) > 0
        ) {
            additionalPayeeAmount =
                (projectFunds *
                    genArtCoreContract.projectIdToAdditionalPayeePercentage(
                        _projectId
                    )) /
                100;
            if (additionalPayeeAmount > 0) {
                IERC20(
                    genArtCoreContract.projectIdToCurrencyAddress(_projectId)
                ).transferFrom(
                        msg.sender,
                        genArtCoreContract.projectIdToAdditionalPayee(
                            _projectId
                        ),
                        additionalPayeeAmount
                    );
            }
        }
        uint256 creatorFunds = projectFunds - additionalPayeeAmount;
        if (creatorFunds > 0) {
            IERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId))
                .transferFrom(
                    msg.sender,
                    genArtCoreContract.projectIdToArtistAddress(_projectId),
                    creatorFunds
                );
        }
    }
}