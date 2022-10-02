// SPDX-License-Identifier: UNLICENSED

/*

                                    .....              ..::^^::..
                          .:~!7777??777!~^:   .^~77?????????77!~:.
                       :~7?????77777777?????77????777777777777????!^.
                    .~7??7777777777777777777??77777777777777777777???~.
                  .~??77777777????777777777777777777777???????7777777??~
                 ^??777777???777777??7777777777777777??7~~~~!7???777777?7:
                !?777777??!^.      .~777777777777777?!.       .:!??77777??^
               7?77777??~.           :?77777777777777            .!?77777??^
              :!!7??7?!.             :?77777777777777^:.           :7???7!~~.
      .:~!!!!!~^^:^!?~           :~!7?777777777777777???7~.         .77^::^~!!7!!~^.
    :!777777777777~::         :!???????777777777777????????7:        .:~777777777777!:
   !7777777777777777~       ^7??7!~~~~~7??777777?77!~~~!!7???7:      ^7777777777777777!.
  !777777777777777777!    :7??~^!J5PGPY!^!?777?7~^7J5P5Y7~^!???!    ~7777777777777777777.
 ~77777777777777777777^  ~??!:7G########G^^?7?!:JB########5~^7??7. :77777777777777777777!
 !77777777777777777777! ~??^^G############!:?!.G############Y:!??7 ~777777777777777777777
 !77777777777777777777~.??^:###############:~.5##############G.!??.^777777777777777777777
 ^77777777777777777777.^?! :?P#############5 ~##############P? .7?~.77777777777777777777^
  ~777777777777777777^.7?.^~BJ7YG##########B ?###########GJ7JY:^^??::777777777777777777~
   ^777777777777777!.:7?7.P:&&&J .~?5PGGGP5! .YGBBBBG5?~.^G#&J!J.?7?..!777777777777777^
     ^!7777777777~:  !??!.B:G&&7      7555P#~YG55YY.     .&&&^5Y.?7?.  :~7777777777!^
       ..:^^^^:.     ~?77.G~J#PY:    .5Y?7!~.^!7?YG~     7B&#:#!^?7?.     .:^^^^:.
                     ~?7?^^Y.75GBBBY..::^^^^^^^^^:::.?GGGPY7^~G.777?.
                     :?77?:^7#####G ^~~^^^^^^^^^^~~~^.P#####!?:~?777
                      7777?~~YB###B~.:^^^~~~~~~~^^^:.^B####B?:!?77?~
                      ^?77??~.^B####P?~^:::::::::^~75#####7.^??77?7.
                       !??~^7PB########BBGP555PGGB########B5!^!???:
                        !:!B######G555P###########BGGB#######P!^7^
                         ~#######7.:&&?.?5PBBBG5!?PGG::7B######Y
                          ~B####B.^^!?^ J5J~.7JGY:YJ7:~:^#####5.
                            !G###5::.JP#~.J! 7P! !J?.~~.!###5:
                              ^JG#B?^5GGJ~5J~JP!.#&P.^^JBP!.
                                 :!YPPGGB#####BGP55J?J?~.
                                      .^~77??J??7~^..


    Limited-edition drops exclusive to LILKOOL supporters and collectors.

    Spacelooters brought to you by Special Delivery & Nclyne.
*/

pragma solidity ^0.8.17;

import "erc721a/extensions/ERC721ABurnable.sol";
import "openzeppelin-contracts/token/common/ERC2981.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/PullPayment.sol";
import "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";

contract Spacelooters is ERC721ABurnable, ERC2981, Ownable, PullPayment {
    using SignatureChecker for address;

    // Maximum number of tokens that may be minted.
    uint256 public constant MAXIMUM_TOKENS = 3333;

    // Price of each token to be minted.
    uint256 public constant MINT_PRICE = 0.1 ether;

    // Presale start at Sat Oct 01 2022 19:00:00 GMT-0400 (Eastern Daylight Time).
    uint256 public constant PRESALE_START_TIMESTAMP = 1664676000;

    // Public sale start at Sun Oct 02 2022 19:00:00 GMT-0400 (Eastern Daylight Time).
    // This is 24 hours after the presale.
    uint256 public constant PUBLIC_SALE_START_TIMESTAMP = 1664762400;

    // Sender may only mint up to 10 tokens per transaction.
    uint256 public constant PUBLIC_SALE_MAXIMUM_TOKENS_PER_TRANSACTION = 10;

    // Categories of addresses eligible for presale minting.
    bytes32 public constant KOOL_KID = keccak256("KoolKid");
    bytes32 public constant OG = keccak256("OG");

    // Token allowances for each presale eligible category.
    uint256 public constant KOOL_KIDS_PRESALE_ALLOWANCE = 10;
    uint256 public constant OG_PRESALE_ALLOWANCE = 25;

    // Address of signer for verifying sender address is eligible for presale.
    address private presaleVerifier;

    // Address that should receive payments.
    address private paymentsBeneficiary;

    // Base URI of tokens.
    string private __baseURI;

    // Track how many mints per address during presale.
    mapping(address => uint256) public presaleMintTracker;

    // Is burning tokens enabled?
    bool public burningEnabled;

    /**
     * Presale verifier signer should not be the zero address.
     */
    error PresaleVerifierCannotBeAddressZero();

    /**
     * Payments beneficiary cannot be the zero address.
     */
    error PaymentsBeneficiaryAddressCannotBeAddressZero();

    /**
     * Recipients and token quantities to be be airdropped mismatch in length.
     *  This can only occur during deployment.
     */
    error ConstructorArgsRecipientsAndQuantitiesLengthsDiffer();

    /**
     * The signature for minting could not be verified.
     */
    error SignatureCouldNotBeVerified();

    /**
     * The sender is neither a Kool Kid or OG and may not mint during presale.
     *
     * This error should never be trigged because ineligible addresses should not make it past signature verification.
     */
    error SenderIneligibleForPresale();

    /**
     * Presale has either not yet started or has already ended.
     */
    error PresaleNotActive();

    /**
     * Public sale has not started.
     */
    error PublicSaleNotActive();

    /**
     * Invalid number of tokens requested to be minted.
     * This can be trigged from a sender wanting to mint 0 tokens, more than their allowance,
     * or `MAXIMUM_TOKENS` would be exceeded.
     */
    error BadRequestedMintQuantity();

    /**
     * Incorrect amount of wei (ETH) sent.
     */
    error BadPaymentAmount();

    /**
     * Burning is not enabled.
     */
    error BurningNotEnabled();

    constructor(
        address presaleVerifier_,
        address paymentsBeneficiary_,
        address[] memory recipients,
        uint256[] memory quantities
    ) ERC721A("Spacelooters", "SPL") {
        if (presaleVerifier_ == address(0)) {
            revert PresaleVerifierCannotBeAddressZero();
        }

        if (paymentsBeneficiary_ == address(0)) {
            revert PaymentsBeneficiaryAddressCannotBeAddressZero();
        }

        // Check that lengths of the recipients and quantities arrays are the same.
        if (recipients.length != quantities.length) {
            revert ConstructorArgsRecipientsAndQuantitiesLengthsDiffer();
        }

        // Loop over the airdrop recipients, minting tokens for them and checking too many tokens are not minted.
        uint256 tokensMinted;
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 quantity = 0;

            // Check that the total number of tokens minted does not exceed `MAXIMUM_TOKENS`.
            if ((quantity = quantities[i]) < 1 || (tokensMinted += quantity) > MAXIMUM_TOKENS) {
                revert BadRequestedMintQuantity();
            }

            _mintERC2309(recipients[i], quantity);
        }

        // Set presale verifier address.
        presaleVerifier = presaleVerifier_;

        // Set payments beneficiary address.
        paymentsBeneficiary = paymentsBeneficiary_;

        // Set royalties for beneficiary to 10% (1000 / 10000).
        _setDefaultRoyalty(paymentsBeneficiary, 1000);

        // Burning is enabled by default.
        burningEnabled = false;

        // Set __baseURI;
        __baseURI = "https://spacelooters.nyc3.digitaloceanspaces.com/metadata/";
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721A, IERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @dev Override of {ERC721A-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override (ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }

    function changeVerifier(address presaleVerifier_) external onlyOwner {
        if (presaleVerifier_ == address(0)) {
            revert PresaleVerifierCannotBeAddressZero();
        }

        presaleVerifier = presaleVerifier_;
    }

    function changePaymentsBeneficiary(address paymentsBeneficiary_) external onlyOwner {
        if (paymentsBeneficiary_ == address(0)) {
            revert PaymentsBeneficiaryAddressCannotBeAddressZero();
        }

        paymentsBeneficiary = paymentsBeneficiary_;
    }

    function changeBaseURI(string memory baseURI) external onlyOwner {
        __baseURI = baseURI;
    }

    function mint(uint256 quantity) external payable returns (uint256, uint256) {
        // Check that the public sale has begun.
        if (block.timestamp < PUBLIC_SALE_START_TIMESTAMP) {
            revert PublicSaleNotActive();
        }

        // Check that the sender has not requested to mint fewer than 1 token (0)
        // OR a quantity of token greater than may be minted in a single transaction
        // OR a quantity of tokens that would result in `MAXIMUM_TOKENS` being minted
        uint256 startTokenId = _nextTokenId();
        if (
            (quantity < 1) || (quantity > PUBLIC_SALE_MAXIMUM_TOKENS_PER_TRANSACTION)
                || (startTokenId + quantity > MAXIMUM_TOKENS)
        ) {
            revert BadRequestedMintQuantity();
        }

        // Check the correct amount of wei (ETH) was sent.
        if (msg.value != MINT_PRICE * quantity) {
            revert BadPaymentAmount();
        }

        // Transfer payments to escrow for contract owner.
        _asyncTransfer(paymentsBeneficiary, msg.value);

        // Mint `quantity` tokens and send them to the sender.
        _mint(msg.sender, quantity);

        // Return start and end token ids.
        return (startTokenId, startTokenId + quantity - 1);
    }

    function presaleMint(uint256 quantity, bytes32 presaleCategory, bytes memory signature)
        external
        payable
        returns (uint256, uint256)
    {
        // Check that presale has started and has not yet ended.
        if (block.timestamp < PRESALE_START_TIMESTAMP || block.timestamp >= PUBLIC_SALE_START_TIMESTAMP) {
            revert PresaleNotActive();
        }

        // Get allowance of tokens for sender during presale and revert if they are ineligible.
        uint256 allowance = _getPresaleMintAllowance(presaleCategory, signature);

        // Check that the sender has not requested to mint fewer than 1 token (0)
        // OR a quantity of tokens would result in their allowance being exceeded
        // OR a quantity of tokens that would result in `MAXIMUM_TOKENS` being minted
        uint256 startTokenId = _nextTokenId();
        if (
            quantity < 1 || (presaleMintTracker[msg.sender] += quantity) > allowance
                || startTokenId + quantity > MAXIMUM_TOKENS
        ) {
            revert BadRequestedMintQuantity();
        }

        // Check the correct amount of wei (ETH) was sent.
        if (msg.value != MINT_PRICE * quantity) {
            revert BadPaymentAmount();
        }

        // Transfer payments to escrow for contract owner.
        _asyncTransfer(paymentsBeneficiary, msg.value);

        // Mint `quantity` tokens and send them to the sender.
        _mint(msg.sender, quantity);

        // Return start and end token ids.
        return (startTokenId, startTokenId + quantity - 1);
    }

    /**
     * @dev Enable the ability to burn tokens.
     */
    function enableBurning() external onlyOwner {
        burningEnabled = true;
    }

    /**
     * @dev Disable the ability to burn tokens.
     */
    function disableBurning() external onlyOwner {
        burningEnabled = false;
    }

    /**
     * @dev Override of {ERC721A}
     */
    function burn(uint256 tokenId) public override {
        if (!burningEnabled) {
            revert BurningNotEnabled();
        }

        super.burn(tokenId);
    }

    /**
     * @dev Start counting tokens up from 1 as opposed to 0.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {ERC721A-_baseURI}
     */
    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    /**
     * @dev Get allowance of tokens for sender during presale.
     */
    function _getPresaleMintAllowance(bytes32 presaleCategory, bytes memory signature)
        internal
        view
        returns (uint256)
    {
        // Check if the presale signer says the sender belongs to one of the presale categories, and if not revert.
        if (
            !presaleVerifier.isValidSignatureNow(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        keccak256(abi.encodePacked(address(this), msg.sender, presaleCategory))
                    )
                ),
                signature
            )
        ) {
            revert SignatureCouldNotBeVerified();
        }

        // Check sender presale category and return allowance.
        if (presaleCategory == KOOL_KID) {
            return KOOL_KIDS_PRESALE_ALLOWANCE;
        } else if (presaleCategory == OG) {
            return OG_PRESALE_ALLOWANCE;
        } else {
            // This should not happen because backend will not return a signature for an ineligible address.
            revert SenderIneligibleForPresale();
        }
    }
}