// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "erc721a/contracts/ERC721A.sol";

import "./interfaces/IBurnable.sol";

/**
 * Huxley Comics Issue 5 and 6. It uses ERC721A.
 */
contract HuxleyComicsIssue56 is ERC721A, IBurnable, Ownable {
    using SignatureChecker for address;

    /// @dev Price for public mint. Set after deploy.
    uint256 public publicPrice;

    /// @dev Price for priority mint. Set after deploy.
    uint256 public priority_Price;

    /// @dev Price for redeemptions. Set after deploy.
    uint256 public redeemPrice;

    /// @dev Uri of metada. Set after deploy. 
    string private uri;

    /// @dev address used to sign priority list addresses
    address public signer;

    /// @dev address that can burn tokens
    address public burner;

    /// @dev Sets when public mint active
    bool public canPublicMint;

    /// @dev Sets when can priroity is active
    bool public canPriorityMint;

    /// @dev Sets when can redeem
    bool public canRedeem;

    /// @dev Address to receive a fee
    address private trustedWallet_A;

    /// @dev Address to receive a fee
    address private trustedWallet_B;

    /// @dev Mapping of redemptions - tokenId -> true/false
    mapping(uint256 => bool) public redemptions;

    uint256 constant MAX_SUPPLY = 20220;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token.
     */
    constructor() ERC721A("HUXLEY Comics: ISSUE 5+6", "HUXLEY56") {}

    /// @dev It starts at 40441 because of Huxley Comics Issue 4
    function _startTokenId() internal view override returns (uint256) {
        return 40441;
    }

    /**
     * @dev Priority mint
     *
     * @param _priorityQtyAllowed Amount allowed to mint during Priority mint
     * @param _quantity Amount to mint
     * @param _signature Signature that authorizes an address to mint during priority
     */
    function priorityMint(
        uint256 _priorityQtyAllowed,
        uint256 _quantity,
        bytes memory _signature
    ) external payable {
        require(canPriorityMint, "HT56: cant mint");

        require(_quantity > 0, "HT56: qty is zero");
        require(_quantity <= 40, "HT56: qty is over 40"); 

        require(
            isWhitelisted(
                _signature,
                _priorityQtyAllowed
            ),
            "H56: not whtl"
        );

        uint256 cumulativeMint = _numberMinted(msg.sender) + _quantity;

        require(cumulativeMint <= _priorityQtyAllowed, "HT56: exceeds qty");

        _executeMint(_quantity, priority_Price);
    }

    /**
     * @dev Public mint.
     * @param _quantity amount to mint
     */
    function publicMint(uint256 _quantity) external payable {
        require(canPublicMint, "HT56: Pub mint not allowed");

        require(_quantity > 0, "HT56: qty is zero");
        require(_quantity <= 40, "HT56: qty is over 40"); 

        _executeMint(_quantity, publicPrice);
    }

    /**
     * @dev Mints a certain amount of Tokens.
     * @param _quantity Amount to mint. It should be less than max mint per tx.
     * @param _price Price paid for the mint. It can be price for public mint or a price for priority mint
     */
    function _executeMint(uint256 _quantity, uint256 _price) internal {
        uint256 totalPaid = _price * _quantity;
        require(msg.value >= totalPaid, "HT56: value is low");

        payment();

        mint(msg.sender, _quantity);
    }

    function mint(address _recipient, uint256 _quantity) internal {
        require(totalSupply() + _quantity * 2 <= MAX_SUPPLY, "HT56: amount to mint over total supply");
        _safeMint(_recipient, _quantity * 2);
    }

    /**
     * @dev Number of tokens minted.
     * @param _wallet Wallet 
     */
    function numberMinted(address _wallet) external view returns(uint256 minted) {
        return _numberMinted(_wallet);
    }

    /**
     * @dev Private mint. OnlyOwner can call this function.
     * @param _amountToMint Amount to mint. 1 = 1 Token Issue 5 + 1 Token Issue 6
     * @param _recipient Address to receive token.
     */
    function privateMint(uint256 _amountToMint, address _recipient) external onlyOwner() {
        mint(_recipient, _amountToMint);
    }

    /**
     * @dev Reserved for future utility.
     * @param _tokenIds List of tokens ids to burn.
     */
    function burnBatch(uint256[] memory _tokenIds) public virtual override {
        require(msg.sender == burner, "HT56: Not burner");
        unchecked {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                uint256 _tokenId = _tokenIds[i];
                _burn(_tokenId, false);
            }
        }
    }

    /// @dev redeem tokens
    function redeem(uint256[] memory _tokenIds) external payable {
        require(canRedeem, "HT56: Cannot redeem.");
        unchecked {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                uint256 _tokenId = _tokenIds[i];
                require(ownerOf(_tokenId) == msg.sender, "HT56: Not token owner to redeem");
                redemptions[_tokenId] = true;
            }
        }

        uint256 totalPaid = redeemPrice * _tokenIds.length;
        require(msg.value >= totalPaid, "HT56: redeem value is low");

        unchecked {
            (bool success, ) = trustedWallet_B.call{value: msg.value}("");
            require(success, "HT56: Transfer B failed");
        }
    }

    /**
     * @dev Check if an address is whitelisted. 
     * @param _signature Signature to check.
     * @param _priorityQtyAllowed Quantity allowed to mint during priority mint
     */
    function isWhitelisted(
        bytes memory _signature,
        uint256 _priorityQtyAllowed
    ) internal view returns (bool) {
        bytes32 result =
            keccak256(
                abi.encodePacked(
                    _priorityQtyAllowed,
                    msg.sender
                )
            );
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signer.isValidSignatureNow(hash, _signature);
    }

    /// @dev Split value paid for a token
    function payment() internal {
        unchecked {
            uint256 amount = (msg.value * 85) / 100;
            (bool success, ) = trustedWallet_A.call{value: amount}("");
            require(success, "HT56: Transfer A failed");

            amount = msg.value - amount;
            (success, ) = trustedWallet_B.call{value: amount}("");
            require(success, "HT56: Transfer B failed");
        }
    }

    /// @dev Set base uri. OnlyOwner can call it.
    function setBaseURI(string memory _value) external onlyOwner {
        uri = _value;
    }

    /// @dev Returns base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    /**
     * @dev Updates address of 'signer'
     * @param _signer  New address for 'signer'
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /**
     * @dev Updates address of 'burner'
     * @param _burner  New address for 'burner'
     */
    function setBurner(address _burner) external onlyOwner {
        burner = _burner;
    }

    /**
     * @dev Updates address of 'trustedWallet_A'
     * @param _trustedWallet  New address for 'trustedWallet_A'
     */
    function setTrustedWallet_A(address _trustedWallet) external onlyOwner {
        trustedWallet_A = _trustedWallet;
    }

    /**
     * @dev Updates address of 'trustedWallet_B'
     * @param _trustedWallet  New address for 'trustedWallet_B'
     */
    function setTrustedWallet_B(address _trustedWallet) external onlyOwner {
        trustedWallet_B = _trustedWallet;
    }

    /**
     * @dev Updates value of 'publicPrice'
     * @param _price  New value of 'publicPrice'
     */
    function setPublicPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    /**
     * @dev Updates value of 'prioritycPrice'
     * @param _price  New value of 'prioritycPrice'
     */
    function setPriorityPrice(uint256 _price) external onlyOwner {
        priority_Price = _price;
    }

    /**
     * @dev Updates value of 'redeemPrice'
     * @param _price  New value of 'redeemPrice'
     */
    function setRedeemPrice(uint256 _price) external onlyOwner {
        redeemPrice = _price;
    }

    /**
     * @dev Updates value of 'canRedeem'
     * @param _value  New value of 'canRedeem'
     */
    function setCanRedeem(bool _value) external onlyOwner {
        canRedeem = _value;
    }

    /**
     * @dev Updates value of 'canPublicMint'
     * @param _value  New value of 'canPublicMint'
     */
    function setCanPublicMint(bool _value) external onlyOwner {
        canPublicMint = _value;
    }

    /**
     * @dev Updates value of 'canPrioritycMint'
     * @param _value  New value of 'canPriorityMint'
     */
    function setCanPriorityMint(bool _value) external onlyOwner {
        canPriorityMint = _value;
    }
}