// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "./interfaces/IBurnable.sol";

import "./ERC721A.sol";

/**
 * Huxley Comics Issue 4. It uses ERC721A.
 */
contract HuxleyComicsIssue4 is ERC721A, IBurnable, Ownable {
    using SignatureChecker for address;

    /// @dev Price for one token. Set after deploy.
    uint256 public price;

    /// @dev Uri of metada. Set after deploy. 
    string private uri;

    /// @dev address used to sign priority list addresses
    address public signer;

    /// @dev address that can burn tokens
    address public burner;

    /// @dev Currrent mint phase
    uint256 public currentPhase;

   /// @dev Max amount of tokens that can be minted in one tx
    uint256 public maxMintPerTransaction;

    /// @dev Sets when public mint (without a need to use a signature to mint)
    bool public canPublicMint;

    /// @dev Sets when can phase mint is allowed
    bool public canPhaseMint;

    /// @dev Sets when can redeem copy
    bool public canRedeemCopy;

    /// @dev Address to receive a fee
    address private trustedWallet_A;

    /// @dev Address to receive a fee
    address private trustedWallet_B;

    /// @dev Mapping of redemptions - tokenId -> true/false
    mapping(uint256 => bool) public redemptions;

    /// @dev PRE_MINT value
    uint256 public constant PRE_MINT = 100;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token.
     */
    constructor() ERC721A("HUXLEY Comics: ISSUE 4", "HUXLEY4") {}

    /**
     * @dev It mints in phases. Address to mint should be whitelisted using a signature.
     *      Priority Phase is until 7. After Phase 7, it is Pre Mint Phase.
     *
     * @param _priorityStartingPhase Priority phase - from 1 to 7
     * @param _priorityQtyAllowed Amount allowed to mint during Priority phase
     * @param _preMintStartingPhase Pre Mint phase - it starts from 8
     * @param _preMintQtyAllowed Amount allowed to mint during pre Mint phase
     * @param _quantity Amount to mint.
     * @param _signature Signature that authorizes and address to mint during priority or pre mint phase
     */
    function phaseMint(
        uint256 _priorityStartingPhase,
        uint256 _priorityQtyAllowed,
        uint256 _preMintStartingPhase,
        uint256 _preMintQtyAllowed,
        uint256 _quantity,
        bytes memory _signature
    ) external payable {
        require(canPhaseMint, "HT4: cant mint");
        require(_quantity > 0, "HT4: qty is zero");

        require(
            isWhitelisted(
                _signature,
                _priorityStartingPhase,
                _priorityQtyAllowed,
                _preMintStartingPhase,
                _preMintQtyAllowed
            ),
            "HT4: not whtl"
        );

        uint256 cumulativeMint = _numberMinted(msg.sender) + _quantity;

        if (currentPhase <= 7) {
            // priority phases
            require(_priorityStartingPhase > 0, "HT4: not allowed");
            require(_priorityStartingPhase <= currentPhase, "HT4: priorPh over crnt phase");
            require(cumulativeMint <= _priorityQtyAllowed, "HT4: already minted allowed");
        } else {
            // premint phases
            if (_priorityStartingPhase > 0) {
                // I'm allowed on priority, but priority should be less than 7 (extra check)
                require(_priorityStartingPhase <= 7, "HT4: priorPh over crnt phase");

                // I am allowed to mint during preMint and I am in correct phase?
                // so check if amount of tokens minteds are greater than total
                if (_preMintStartingPhase > 0) {
                    // I can mint all the things
                    if (_preMintStartingPhase <= currentPhase) {
                        require(
                            cumulativeMint <= _priorityQtyAllowed + _preMintQtyAllowed,
                            "HT4: priorQty and preMintQty over max"
                        );
                    } else {
                        require(cumulativeMint <= _priorityQtyAllowed, "HT4: priorQty over max");
                    }
                } else {
                    // _preMintStartingPhase == 0 -> Cannot preMint
                    // I can only mint up to my priority minting allowed
                    require(cumulativeMint <= _priorityQtyAllowed, "HT4: already minted allowed");
                }
            } else {
                // user is not allowed to priorityMint
                require(_preMintStartingPhase > 0, "HT4: not allowed");

                //check if correct phase
                require(_preMintStartingPhase <= currentPhase, "HT4: preMintPh over crnt phase");

                //check amount minted
                require(cumulativeMint <= _preMintQtyAllowed, "HT4: preMintQty over max");
            }
        }

        mint(_quantity);
    }

    /**
     * @dev It is a public mint. It isn't necessary to be whitelisted or use a signature.
     * @param _quantity Amount to mint. It should be less than max mint per tx
     */
    function publicMint(uint256 _quantity) external payable {
        require(canPublicMint, "HT4: Pub mint not allowed");
        mint(_quantity);
    }

    /**
     * @dev Mints a certain amount of Tokens.
     * @param _quantity Amount to mint. It should be less than max mint per tx.
     */
    function mint(uint256 _quantity) internal {
        require(_quantity <= maxMintPerTransaction, "HT4: qty over maxPerTx");
        require(hasFirstEditionSupplyLeft(_quantity), "HT4: qty over supply");

        uint256 totalPaid = price * _quantity;
        require(msg.value >= totalPaid, "HT4: value is low");

        payment();

        _safeMint(msg.sender, _quantity);
    }

    /**
     * @dev Private mint. OnlyOwner can call this function.
     * @param _amountToMint Amount to mint.
     * @param _recipient Address to receive token.
     */
    function privateMint(uint256 _amountToMint, address _recipient) external onlyOwner() {
        _safeMint(_recipient, _amountToMint);
    }

    /**
     * @dev Reserved for future utility.
     * @param _tokenIds List of tokens ids to burn.
     */
    function burnBatch(uint256[] memory _tokenIds) public virtual override {
        require(msg.sender == burner, "HT4: Not burner");
        unchecked {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                uint256 _tokenId = _tokenIds[i];
                _burn(_tokenId, false);
            }
        }
    }

    /// @dev User can redeem a copy
    function redeemCopy(uint256[] memory _tokenIds) external {
        require(canRedeemCopy, "HT4: Cannot redeem.");
        unchecked {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                uint256 _tokenId = _tokenIds[i];
                if (ownerOf(_tokenId) == msg.sender) {
                    redemptions[_tokenId] = true;
                }
            }
        }
    }

    /**
     * @dev Check if an address is whitelisted. 
     * @param _signature Signature to check.
     * @param _priorityStartingPhase Priority start phase
     * @param _priorityQtyAllowed Quantity allowed to mint during priority phase
     * @param _preMintStartingPhase Pre mint start phase
     * @param _preMintQtyAllowed Quantity allowed to mint during pre mint
     */
    function isWhitelisted(
        bytes memory _signature,
        uint256 _priorityStartingPhase,
        uint256 _priorityQtyAllowed,
        uint256 _preMintStartingPhase,
        uint256 _preMintQtyAllowed
    ) internal view returns (bool) {
        bytes32 result =
            keccak256(
                abi.encodePacked(
                    _priorityStartingPhase,
                    _priorityQtyAllowed,
                    _preMintStartingPhase,
                    _preMintQtyAllowed,
                    msg.sender
                )
            );
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signer.isValidSignatureNow(hash, _signature);
    }

    /**
     * @dev Returns if it has supply lefted. It is calculated using amount of tokens minted + amount to mint
     * @param _quantity Amount to mint 
     */
    function hasFirstEditionSupplyLeft(uint256 _quantity) internal view returns (bool) {
        uint256 totalFirstEditionMinted = totalSupply() - PRE_MINT + _quantity;
        return totalFirstEditionMinted <= 10000;
    }

    /// @dev Split value paid for a token
    function payment() internal {
        unchecked {
            uint256 amount = (msg.value * 85) / 100;
            (bool success, ) = trustedWallet_A.call{value: amount}("");
            require(success, "HT4: Transfer A failed");

            amount = msg.value - amount;
            (success, ) = trustedWallet_B.call{value: amount}("");
            require(success, "HT4: Transfer B failed");
        }
    }

    /// @dev Sets a mint phase. OnlyOwner can call it.
    function setPhase(uint256 _phase) external onlyOwner {
        currentPhase = _phase;
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
     * @dev Updates value of 'price'
     * @param _price  New value of 'price'
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @dev Updates value of 'canRedeemCopy'
     * @param _value  New value of 'canRedeemCopy'
     */
    function setCanRedeemCopy(bool _value) external onlyOwner {
        canRedeemCopy = _value;
    }

    /**
     * @dev Updates value of 'maxMintPerTransaction'
     * @param _value  New value of 'maxMintPerTransaction'
     */
    function setMaxMintPerTransaction(uint256 _value) external onlyOwner {
        maxMintPerTransaction = _value;
    }

    /**
     * @dev Updates value of 'canPhaseMint'
     * @param _value  New value of 'canPhaseMint'
     */
    function setCanPhaseMint(bool _value) external onlyOwner {
        canPhaseMint = _value;
    }

    /**
     * @dev Updates value of 'canPublicMint'
     * @param _value  New value of 'canPublicMint'
     */
    function setCanPublicMint(bool _value) external onlyOwner {
        canPublicMint = _value;
    }
}