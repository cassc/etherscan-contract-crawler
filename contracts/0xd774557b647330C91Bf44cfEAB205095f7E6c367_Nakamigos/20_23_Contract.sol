// SPDX-License-Identifier: MIT
/*
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▄▄▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▄▄░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓''''''''''▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░▄▄▄▄▄▄▄▄▄▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▄▄▄▄▄▄▄▄▄▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░⌐      ░░░░      ░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░   j▓▓▓░░░   j▓▓▓░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░,,,j▀▀▀░░░,,,j▀▀▀░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░░░░░▄▄▄▄▄▄▄▄▄▄░░░░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░░░░▐▓▓▓▓▓▓▓▓▓▓░░░░░░▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░▐▓▓▓░░░░░░░░░░░░░░░░░░░░▓▓▓▌░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░▄▄▄▄▄▄▐▓▓▓▄▄▄µ░░░░░░░░░░░░╔▄▄▄▓▓▓▌░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▌░░░░░░╬╬╬╬╬╬╣▓▓▓▓▓▓▌░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░▐▓▓▓▀╬╬╬╬╬╬╬╬╬▓▓▓▌░░░░░░░░░╠░░╟▓▓▓╬╬╬▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░Q▄▄▐▓▓▓▄▄▄▄▄▄▄╬╬╬▓▓▓▌▄▄▄░░░░░░╚╩╩╣▓▓▓▒▒▒▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░▓▓▓▓▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▓▓▓▓░░░░░░░░░▐▓▓▓▒▒▒▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓└└└└└└▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░
░░░░░░░▄▄▄▓▓▓▓╬╬▓███⌐     ▐███▓▓▓▓╬╬╣▓▓▓▓▓▓▓▓▓▓╬╬╬▓▓▓▓██████▄▄▄░░░░░░░░░░░░░░░░░
░░░░░░▐▓▓▓▒▒▒▓▓▓▌             ▓▓▓▓▓▓▓╬╬╬░░░╫╬╬╣▓▓▓▓▓▓▌      ▓▓▓▌░░░░░░░░░░░░░░░░
░░░░░░▐▓▓▓▒▒▒▓▓▓▌             ```▓▓▓▓░░░░░░░░░▐▓▓▓```       ▓▓▓▌░░░░░░░░░░░░░░░░
░░░░░░▐▓▓▓▒▒▒▓▓▓▌                ███▓░░░░░░░░░▐███          ▓▓▓▌░░░░░░░░░░░░░░░░
░░░▓▓▓▓▓▓▓▒▒▒▓▓▓▌      ╟▓▓▌          ░░░░░░║░░╡      ▓▓▓▌   ▓▓▓▌░░░░░░░░░░░░░░░░
░░░▓▓▓▓▓▓▓▒▒▒▓▓▓▌      ╟▓▓▌                          ▓▓▓▌   ▓▓▓▌░░░░░░░░░░░░░░░░
░░░▓▓▓▓▓▓▓▒▒▒▓▓▓▌      ╟▓▓▌                          ▓▓▓▌   ▓▓▓▌░░░░░░░░░░░░░░░░
░░░▓▓▓▓▓▓▓▒▒▒▓▓▓▌      ╟▓▓▌                          ▓▓▓▌   ▓▓▓▌░░░░░░░░░░░░░░░░
 */
pragma solidity ^0.8.17;

import "./lib/ERC721AOpensea.sol";
import "./lib/IWCNFTErrorCodes.sol";
import "./lib/WCNFTMerkle.sol";
import "./lib/WCNFTToken.sol";
import "./lib/SteppedDutchAuctionLean.sol";
import "./IDelegationRegistryExcerpt.sol";

contract Nakamigos is
    IWCNFTErrorCodes,
    SteppedDutchAuction,
    WCNFTMerkle,
    WCNFTToken,
    ERC721AOpensea
{
    // state vars
    uint256 public constant MAX_SUPPLY = 20000;
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 10;

    string public provenance;
    string private _baseURIextended;

    address public snapshotContract;
    address payable public immutable shareholderAddress;
    address private constant _DELEGATION_REGISTRY =
        0x00000000000076A84feF008CDAbe6409d2FE638B;

    // *************************************************************************
    // CUSTOM ERRORS

    /// not accepting mints from contracts on the Dutch Auction
    error NoContractMinting();

    /// check delegate.cash for delegation
    error NotDelegatedOnContract();

    /// refund of excess payment failed
    error RefundFailed();

    /// snapshot contract address must be set
    error SnapshotContractNotSet();

    // *************************************************************************
    // EVENTS

    /**
     * @dev emit when a user mints on the Dutch auction
     * @param userAddress the minting wallet and token recipient
     * @param numberOfTokens the quantity of tokens purchased
     */
    event DutchAuctionMint(address indexed userAddress, uint256 numberOfTokens);

    /**
     * @dev emit when a user claims tokens on the allowlist
     * @param userAddress the minting wallet and token recipient
     * @param vault an address in the snapshot, if using delegation, or 0x00..00
     * @param numberOfTokens the quantity of tokens claimed
     */
    event AllowListClaimMint(
        address indexed userAddress,
        address indexed vault,
        uint256 numberOfTokens
    );

    // *************************************************************************
    // MODIFIERS

    /**
     * @dev revert if minting a quantity of tokens would exceed the maximum supply
     * @param numberOfTokens the quantity of tokens to be minted
     */
    modifier supplyAvailable(uint256 numberOfTokens) {
        if (_totalMinted() + numberOfTokens > MAX_SUPPLY) {
            revert ExceedsMaximumSupply();
        }
        _;
    }

    // *************************************************************************
    // FUNCTIONS

    /**
     * @param shareholderAddress_ recipient for all ETH withdrawals
     */
    constructor(address payable shareholderAddress_)
        ERC721A("Nakamigos", "NKMGS")
        ERC721AOpensea()
        WCNFTToken()
    {
        if (shareholderAddress_ == address(0)) revert ZeroAddressProvided();
        shareholderAddress = shareholderAddress_;
    }

    // *************************************************************************
    // CLAIM - Allowlist claim from EOS snapshot

    /**
     * @notice claim tokens 1-for-1 against your EOS holdings at the snapshot.
     *  If EOS holdings were in a different wallet, delegate.cash may be used to
     *  delegate a different wallet to make this claim, e.g. a "hot wallet".
     *  If using delegation, ensure the hot wallet is delegated on the EOS
     *  contract, or the entire vault wallet.
     *  NOTE delegate.cash is an unaffiliated external service, use it at your
     *  own risk! Their docs are available at http://delegate.cash
     *
     * @param vault if using delegate.cash, the address that held EOS tokens in
     *  the snapshot. Set this to 0x000..000 if not using delegation.
     * @param numberOfTokens the number of tokens to claim
     * @param tokenQuota the total quota of tokens for the claiming address
     * @param proof the Merkle proof for this claimer
     */
    function mintAllowList(
        address vault,
        uint256 numberOfTokens,
        uint256 tokenQuota,
        bytes32[] calldata proof
    )
        external
        isAllowListActive
        supplyAvailable(numberOfTokens)
    {
        address claimer = msg.sender;

        // check vault if using delegation
        if (vault != address(0) && vault != msg.sender) {
            if (
                !(
                    IDelegationRegistry(_DELEGATION_REGISTRY)
                        .checkDelegateForContract(
                            msg.sender,
                            vault,
                            snapshotContract
                        )
                )
            ) {
                revert NotDelegatedOnContract();
            }

            // msg.sender is delegated for vault
            claimer = vault;
        }

        // check if the claimer has tokens remaining in their quota
        uint256 tokensClaimed = getAllowListMinted(claimer);
        if (tokensClaimed + numberOfTokens > tokenQuota) {
            revert ExceedsAllowListQuota();
        }

        // check if the claimer is on the allowlist
        if (!onAllowListB(claimer, tokenQuota, proof)) {
            revert NotOnAllowList();
        }

        // claim tokens
        _setAllowListMinted(claimer, numberOfTokens);
        _safeMint(msg.sender, numberOfTokens, "");
        emit AllowListClaimMint(msg.sender, vault, numberOfTokens);
    }

    /**
     * @notice start and stop the Claim sale
     * @param isActive true activates the Claim, false de-activates it
     */
    function setAllowListActive(bool isActive)
        external
        override
        onlyRole(SUPPORT_ROLE)
    {
        if (auctionActive) revert DutchAuctionIsActive();
        if (snapshotContract == address(0)) revert SnapshotContractNotSet();
        if (merkleRoot == bytes32(0)) revert MerkleRootNotSet();

        _setAllowListActive(isActive);
    }

    /**
     * @dev set the contract used in the snapshot for the claim phase. This is
     *  referred to when using wallet delegation via delegate.cash.
     * @param snapshotContract_ address of the snapshot contract
     */
    function setSnapshotContract(address snapshotContract_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        if (snapshotContract_ == address(0)) revert ZeroAddressProvided();
        snapshotContract = snapshotContract_;
    }

    // *************************************************************************
    // STEPPED DUTCH AUCTION

    /**
     * @notice initialize a new Dutch auction. Price will step down in fixed
     *  amounts, at fixed time intervals, until it hits the final resting price,
     *  where it remains until the auction is ended
     *
     * @dev if the prices do not divide perfectly, the final price step will be
     *  smaller than the rest, i.e. it will stop at finalPrice_.
     *  NOTE calling this multiple times will overwrite the previous parameters.
     *  See {_createNewAuction() in SteppedDutchAuction.sol}
     *
     * @param startPrice_ starting price in wei
     * @param finalPrice_ final resting price in wei
     * @param priceStep_ incremental price decrease in wei
     * @param timeStepSeconds_ time between each price decrease in seconds
     */
    function createDutchAuction(
        uint256 startPrice_,
        uint256 finalPrice_,
        uint256 priceStep_,
        uint256 timeStepSeconds_
    )
        external
        onlyRole(SUPPORT_ROLE)
    {
        _createNewAuction(
            startPrice_,
            finalPrice_,
            priceStep_,
            timeStepSeconds_
        );
    }

    /**
     * @notice Mint tokens on the Dutch auction. To get the current price use
     *  getAuctionPrice().
     * @param numberOfTokens the quantity of tokens to mint
     */
    function mintDutch(uint256 numberOfTokens)
        external
        payable
        isAuctionActive
        supplyAvailable(numberOfTokens)
    {
        if (msg.sender != tx.origin) revert NoContractMinting();

        if (numberOfTokens > MAX_TOKENS_PER_PURCHASE) {
            revert ExceedsMaximumTokensPerTransaction();
        }

        uint256 price = getAuctionPrice() * numberOfTokens;
        if (msg.value < price) revert WrongETHValueSent();

        _safeMint(msg.sender, numberOfTokens, "");
        emit DutchAuctionMint(msg.sender, numberOfTokens);

        // if the price drops before the tx confirms, the user should pay the
        // amount at tx confirmation.
        if (msg.value > price) {
            (bool success, ) = msg.sender.call{value: (msg.value - price)}("");
            if (!success) revert RefundFailed();
        }
    }

    /**
     * @notice start a Dutch Auction that has been set up with
     *  createDutchAuction()
     * @dev See {_startAuction() in SteppedDutchAuction.sol}
     */
    function startDutchAuction() external onlyRole(SUPPORT_ROLE) {
        if (allowListActive) revert AllowListIsActive();

        _startAuction();
    }

    /**
     * @dev if a Dutch auction was stopped using stopDutchAuction it can be
     *  resumed with this function. No time is added to the duration so all
     *  elapsed time during the pause is lost.
     *
     * To restart a stopped Dutch auction from the startPrice with its full
     * duration, use _startAuction() again.
     */
    function resumeDutchAuction() external onlyRole(SUPPORT_ROLE) {
        if (allowListActive) revert AllowListIsActive();

        _resumeAuction();
    }

    /**
     * @notice stop the currently active Dutch Auction
     * @dev See {_stopAuction() in SteppedDutchAuction.sol}
     */
    function stopDutchAuction() external onlyRole(SUPPORT_ROLE) {
        _endAuction();
    }

    // *************************************************************************
    // ADMIN & DEV

    /**
     * @dev mint reserved tokens
     * @param to the recipient address
     * @param numberOfTokens the quantity of tokens to mint
     */
    function devMint(address to, uint256 numberOfTokens)
        external
        supplyAvailable(numberOfTokens)
        onlyRole(SUPPORT_ROLE)
    {
        _safeMint(to, numberOfTokens);
    }

    /**
     * @dev set the base URI for the collection, returned from {_baseURI()}
     * @param baseURI_ the new base URI
     */
    function setBaseURI(string calldata baseURI_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev set the provenance hash
     * @param provenance_ the provenance hash
     */
    function setProvenance(string calldata provenance_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        provenance = provenance_;
    }

    /**
     * @dev withdraw all funds
     */
    function withdraw() external onlyOwner {
        (bool success, ) = shareholderAddress.call{
            value: address(this).balance
        }("");
        if (!success) revert WithdrawFailed();
    }

    // *************************************************************************
    // OVERRIDES

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, WCNFTToken, ERC721AOpensea)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721A-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
}