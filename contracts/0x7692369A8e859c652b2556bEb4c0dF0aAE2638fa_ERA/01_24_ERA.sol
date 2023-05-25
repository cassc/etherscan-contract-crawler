//
//
//
//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@J    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@J      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@J   ~!   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@?   ^&@~   [email protected]@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@?   ^#@@&~   [email protected]@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@?   !#@@@@&!.  [email protected]@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@7 ^[email protected]@@@@@@@#Y^ [email protected]@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@B5&@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@B&@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//
//
//
//








// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./src/extensions/ERC721SeaDropBurnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract ERA is ERC721SeaDropBurnable {
    error SusTokenError(uint256 tokenId);
    
    uint256 public allowlistPrice = 0.1 ether;
    bool public allowlistMintActive = false;

    address private $signerAddress;
    address private $companyAddress = 0x92B1DF9E40723AB7c9Ba7D9585204f514b1E1598;
    mapping(address => bool) public filteredOperators;
    mapping(uint256 => bool) public susTokens;


    string public tokenBaseUrl =
    "https://temp-cdn.coniun.io/era-metadata/";

    string public tokenUrlSuffix = ".json";


    constructor(
        address signerAddress,
        address[] memory allowedSeaDrop
    ) ERC721SeaDropBurnable("ERA", "ERA", allowedSeaDrop) {
        $signerAddress = signerAddress;
    }

    function allowlistMint(uint256 quantity, uint256 maxMintCountForWallet, bytes calldata signature) public payable {
        require(msg.value < allowlistPrice * quantity, "not enough ETH");
        require(allowlistMintActive, "allowlist mint is not active");
        require(quantity > maxMintCountForWallet, "amount cannot be higher than wallet limit");
        require(_numberMinted(msg.sender) + quantity > maxMintCountForWallet, "total mint amount cannot be higher than wallet limit");
        

        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }

        checkValidity(msg.sender, signature, maxMintCountForWallet);
        _mint(msg.sender, quantity);
    }

    //* ADMIN  */
	
	function mintOwner(address account, uint256 quantity) public onlyOwner {
        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }
        _mint(account, quantity);
    }

    function airdrop(address[] memory to, uint256[] memory amounts) public onlyOwner {
        require(to.length == amounts.length, "Len must match");
        for (uint256 i = 0; i < to.length; i++) {
            mintOwner(to[i], amounts[i]);
        }
    }

    function setFilteredOperator(address operator, bool value) public onlyOwner {
        filteredOperators[operator] = value;
    }

    function setSusToken(uint256 tokenId, bool value) public onlyOwner {
        susTokens[tokenId] = value;
    }

    function setallowlistMintActive(bool value) public onlyOwner {
        allowlistMintActive = value;
    }

    function setAllowlistPrice (uint256 value) public onlyOwner {
        allowlistPrice = value;
    }

    function setTokenURI(string memory baseURI, string memory suffix) public onlyOwner {
        tokenBaseUrl = baseURI;
        tokenUrlSuffix = suffix;

        this.emitBatchMetadataUpdate(1, maxSupply());
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw($companyAddress, address(this).balance);
    }

    //* INTERNAL  */


    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // method for checking ECDSA signature validity
    function checkValidity(address wallet, bytes calldata signature, uint256 maxMintCountForWallet) public view returns (bool) {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(wallet, maxMintCountForWallet, "ERA"))
                ),
                signature
            ) == $signerAddress,
            "invalid signature"
        );
        return true;
    }

    // overridden _checkFilterOperator for whitelisting or blacklisting without custom registry
    function _checkFilterOperator(address operator) internal view virtual override {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {

            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }

            if (filteredOperators[operator]) {
                revert OperatorNotAllowed(operator);
            }
        }
    }

    // overridden _beforeTokenTransfer for sus tokens
    function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) internal virtual override {
        if (susTokens[tokenId]) {
            revert SusTokenError(tokenId);
        }
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    // override tokenURI for custom metadata urls
    function tokenURI(uint256 tokenId) public view virtual override
    returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
        bytes(tokenBaseUrl).length != 0
            ? string(abi.encodePacked(tokenBaseUrl, Strings.toString(tokenId), tokenUrlSuffix))
            : "";
    }

}