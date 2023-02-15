//SPDX-License-Identifier: MIT
// Agoradex Contracts v1.0.0
// Creator: Nefture

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../libraries/ECDSALibrary.sol";
import "./ERC721A.sol";
import "./IAgoradex.sol";

// ............................................................................................................................................................
// ............................................................................................................................................................
// ............................................................................................................................................................
// .................................................................,:;+?%SS##@@@@@@@@##S%%?+;:,...............................................................
// ........................................................,;?S#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#S*;,......................................................
// .....................................................,+%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#%+,...................................................
// ..................................................,;%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#%;,................................................
// ..............................................:?#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#?:............................................
// ............................................,*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*,..........................................
// ...........................................+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+.........................................
// ........................................:#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:......................................
// .......................................;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;.....................................
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##########@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+....................................
// ....................................:#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@;..........;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:..................................
// ....................................%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,.................................
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?......,,......*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+.................................
// ..................................;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@S,......*@@%......,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+................................
// ..................................%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:[email protected]@@@*......,#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%................................
// ..................................#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:......:@@@@@@+......:#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#................................
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*......,%@@@@@@@@S,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@................................
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@%,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@................................
// ..................................#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,......*@@@@@?*@@@@@?......,%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#................................
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@#:......:#@@@@#:..,[email protected]@@@@;......:#@@@@@@@@@@@@@@@@@@@@@@@@@@@;................................
// ..................................,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@;......,[email protected]@@@@+....,#@@@@#:......;@@@@@@@@@@@@@@@@@@@@@@@@@@S,................................
// [email protected]@@@@@@@@@@@@@@@@@@@@@@@@+......,%@@@@@?......:@@@@@S,[email protected]@@@@@@@@@@@@@@@@@@@@@@@@+.................................
// ....................................:#@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@?.......*@@@@@*[email protected]@@@@@@@@@@@@@@@@@@@@#:..................................
// .....................................;@@@@@@@@@@@@@@@@@@@@S,,,,,,,;@@@@@@@@@@+,,,,,,,%@@@@@;,,,,,,,[email protected]@@@@@@@@@@@@@@@@@@@;...................................
// [email protected]@@@@@@@@@@@@@@@@@@########@@@@@@@@@@@@########@@@@@@########@@@@@@@@@@@@@@@@@@@+....................................
// ........................................:#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:......................................
// .........................................,%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,.......................................
// ...........................................+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+.........................................
// ..............................................:?#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#?:............................................
// ................................................:*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*:..............................................
// ..................................................,;%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#%;,................................................
// ........................................................,;*S#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#S?;,......................................................
// ............................................................,;*?S#@@@@@@@@@@@@@@@@@@@@@@@@@@#S?+;,..........................................................
// .................................................................,:;+?%%S##@@@@@@@@##SS%?+;:,...............................................................
// ............................................................................................................................................................
// ............................................................................................................................................................
// ............................................................................................................................................................
// ............................................................................................................................................................
// ............................................................................................................................................................
// ............................................................................................................................................................
// ......,%#S#%,........................,+?S#@@@@@#%*;,....................,;?S#@@@@@#S*;,.................*#####S%*:.......................,S#S#?.............
// [email protected]@@@@?......................:%#@@S?*++*?%#@@#+,................,*#@@#%*+++*%#@@#*,...............;?????%#@@%:....................,[email protected]@@@@*............
// .....*@@#;[email protected]@*....................*@@@*:........,;%*;,...............;#@@%:........,;%@@#:.....................,%@@S,...................%@@S;#@@+...........
// [email protected]@@;.:#@@+..................;@@@;..............................,#@@[email protected]@S,....................,%@@S,..................*@@#:.;@@@;..........
// ...;@@@+...;@@@;.................*@@#.......*%%%%%%%%%+.............;@@@:.............;@@@:.............;?????%#@@%:[email protected]@@;...*@@#:.........
// ..:#@@*.....*@@#:................;@@@;......*%%%%%%@@@*.............,#@@[email protected]@S,.............+SSS#@@@?:...................;@@@[email protected]@S,........
// .,[email protected]@%[email protected]@#,[email protected]@@*:.........:[email protected]@S,..............;#@@%:........,;%@@#:..................,*@@#;..................:#@@*......,[email protected]@%,.......
// ,[email protected]@S,.......,%@@S,................:%#@@S?*+++*[email protected]@#?,................,*#@@#%*+++*%#@@#*,.....................;[email protected]@?,...............:#@@?........,#@@?,......
// [email protected]##:.........,[email protected]@?..................,+?S#@@@@@#S?+,....................,;?S#@@@@@#S*;,........................,%@@%,.............,%@@S,.........;##@*?.....
// ............................................................................................................................................................
// ............................................................................................................................................................
// ............................................................................................................................................................

contract Agoradex is IAgoradex, ERC721A, Ownable, AccessControl {
    // Access control roles
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant FREE_SIGNER_ROLE = keccak256("FREE_SIGNER_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    // The base token URI
    string private _baseTokenURI;

    // True if the URI been frozen for ever
    bool public isUriFrozenForEver;

    // The nonce used for free mints
    mapping(address => uint256) private nonces;

    // sale times
    uint256 private _saleTime = 1676476800;

    // The Minotaur's initial price
    uint256 private _minotaurPrice = 0.165 ether;
    
    // The Medusa's initial price
    uint256 private _medusaPrice = 0.24 ether;

    // The initial discounts
    uint256[] private _discounts = [100, 95, 90, 80];

    // The token's type
    // false: Minotaure
    // true: Medusa
    mapping(uint256 => bool) private isMedusa;

    // Collection's initial Minotaurs maximum supply
    uint256 private _maxSupplyMinotaurs = 824;

    // Collection's initial Medusas maximum supply
    uint256 private _maxSupplyMedusas = 676;

    // Total number of medusa tokens
    uint256 private _numberMedusas;

    // Number of mint per address
    uint256 private _maxMintPerWallet = 3;
    mapping(address => uint256) internal _numbMint;

    // Payment splitter
    uint256 internal constant totalShares = 1000;
    uint256 internal totalReleased;
    mapping(address => uint256) internal released;
    mapping(address => uint256) internal shares;
    address internal constant project = 0x93eD3714399519c8F6459F882A4B8578864a5a59;
    address internal constant shareHolder2 = 0xcA86752aeB44343d8C8d7Ef09652c81032804d8D;
    
    constructor() ERC721A("AGORA", "AGORA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        shares[project] = 965;
        shares[shareHolder2] = 35;

        _mint(0x93eD3714399519c8F6459F882A4B8578864a5a59, 2);
        _numberMedusas += 1;
        isMedusa[1] = true;

        // set metadata
        _baseTokenURI = "ipfs://QmddYSKWNGGWS3htRBDQv7t7o3xQh6HGtVxSAgsPGERGNW/";
    }

    /*
     * mint tokens as Whitelisted
     *
     * @param _quantityMinotaur: quantity of Minotaur tokens to mint
     * @param _quantityMedusa: quantity of Medusa tokens to mint
     * @param _discountIndex: discount to be applied (90 means 10% discount)
     * @param _signature: whitelist signature
     *
     * Error messages:
     *  - A1: "Wrong price"
     *  - A2: "Can't mint more tokens with this wallet"
     *  - A3: "Max Minotaur supply has been reached"
     *  - A4: "Max Medusa supply has been reached"
     *  - A5: "Mint has not started yet"
     *  - A6: "Wrong signature"
     */
    function whitelistMint(
        uint256 _quantityMinotaur,
        uint256 _quantityMedusa,
        uint256 _discountIndex,
        bytes calldata _signature
    ) external payable {
        require(
            msg.value ==
                ((_minotaurPrice *
                    _quantityMinotaur +
                    _medusaPrice *
                    _quantityMedusa) * _discounts[_discountIndex]) /
                    100,
            "A1"
        );
        require(
            _numbMint[msg.sender] + _quantityMinotaur + _quantityMedusa <=
                _maxMintPerWallet,
            "A2"
        );
        require(
            totalSupply() - _numberMedusas + _quantityMinotaur <=
                _maxSupplyMinotaurs,
            "A3"
        );
        require(_numberMedusas + _quantityMedusa <= _maxSupplyMedusas, "A4");
        require(block.timestamp > _saleTime, "A5");
        _numbMint[msg.sender] += _quantityMinotaur + _quantityMedusa;

        require(
            hasRole(
                SIGNER_ROLE,
                ECDSALibrary.recover(
                    abi.encodePacked(msg.sender, _discounts[_discountIndex]),
                    _signature
                )
            ),
            "A6"
        );

        for (uint i = 1; i < _quantityMedusa + 1; i++) {
            isMedusa[totalSupply() + i] = true;
        }
        _numberMedusas += _quantityMedusa;

        _mint(msg.sender, _quantityMinotaur + _quantityMedusa);
    }

    /*
     * mint tokens as free claims
     *
     * @param _quantityMinotaur: quantity of Minotaur tokens to mint
     * @param _quantityMedusa: quantity of Medusa tokens to mint
     * @param _signature: free claim signature
     *
     * Error messages:
     *  - A2: "Can't mint more tokens with this wallet"
     *  - A3: "Max Minotaur supply has been reached"
     *  - A4: "Max Medusa supply has been reached"
     *  - A6: "Wrong signature"
     */
    function freeClaim(
        uint256 _quantityMinotaur,
        uint256 _quantityMedusa,
        bytes calldata _signature
    ) external {
        require(
            _numbMint[msg.sender] + _quantityMinotaur + _quantityMedusa <=
                _maxMintPerWallet,
            "A2"
        );
        require(
            totalSupply() - _numberMedusas + _quantityMinotaur <=
                _maxSupplyMinotaurs,
            "A3"
        );
        require(_numberMedusas + _quantityMedusa <= _maxSupplyMedusas, "A4");

        uint256 nonce = nonces[msg.sender] + 1;
        require(
            hasRole(
                FREE_SIGNER_ROLE,
                ECDSALibrary.recover(
                    abi.encodePacked(
                        msg.sender,
                        _quantityMinotaur,
                        _quantityMedusa,
                        nonce
                    ),
                    _signature
                )
            ),
            "A6"
        );
        nonces[msg.sender] += 1;

        for (uint i = 1; i < _quantityMedusa + 1; i++) {
            isMedusa[totalSupply() + i] = true;
        }
        _numberMedusas += _quantityMedusa;

        _mint(msg.sender, _quantityMedusa + _quantityMinotaur);
    }

    /*
     * airdrop tokens to address
     *
     * @param _quantityMinotaur: quantity of Minotaur tokens to mint
     * @param _quantityMedusa: quantity of Medusa tokens to mint
     * @param _to: receiver of the tokens
     *
     * Error messages:
     *  - A3: "Max Minotaur supply has been reached"
     *  - A4: "Max Medusa supply has been reached"
     */
    function airdrop(
        uint256 _quantityMinotaur,
        uint256 _quantityMedusa,
        address _to
    ) public onlyRole(AIRDROP_ROLE) {
        require(
            totalSupply() - _numberMedusas + _quantityMinotaur <=
                _maxSupplyMinotaurs,
            "A3"
        );
        require(_numberMedusas + _quantityMedusa <= _maxSupplyMedusas, "A4");

        for (uint i = 1; i < _quantityMedusa + 1; i++) {
            isMedusa[totalSupply() + i] = true;
        }
        _numberMedusas += _quantityMedusa;

        _mint(_to, _quantityMedusa + _quantityMinotaur);
    }

    /*
     * airdrop tokens to addresses in batches
     *
     * @param _quantityMinotaur: array of quantities of Minotaur tokens to mint per address
     * @param _quantityMedusa: array of quantities of Medusa tokens to mint per address
     * @param _to: array of receivers of the tokens
     *
     * Error messages:
     *  - A7: "Entries don't match length"
     */

    function batchAirdrop(
        uint256[] calldata _quantityMinotaur,
        uint256[] calldata _quantityMedusa,
        address[] calldata _to
    ) external onlyRole(AIRDROP_ROLE) {
        require(
            (_quantityMinotaur.length == _to.length) &&
                (_quantityMedusa.length == _to.length),
            "A7"
        );

        for (uint i = 0; i < _to.length; i++) {
            airdrop(_quantityMinotaur[i], _quantityMedusa[i], _to[i]);
        }
    }

    /*
     * set maximum mint quantity per wallet
     *
     * @param _newMaxMint: new value for maximum mint per wallet
     */
    function setMaxMintsPerWallet(uint256 _newMaxMint) external onlyOwner {
        _maxMintPerWallet = _newMaxMint;
    }

    /*
     * change price of tokens
     *
     * @param _newMinotaurPrice: new value for Minotaur's mint price
     * @param _newMedusaPrice: new value for Medusa's mint price
     */
    function setSalePrices(
        uint256 _newMinotaurPrice,
        uint256 _newMedusaPrice
    ) external onlyOwner {
        _minotaurPrice = _newMinotaurPrice;
        _medusaPrice = _newMedusaPrice;
    }

    /*
     * change discounts for tokens
     *
     * @param _newDiscounts: new discounts array
     */
    function setDiscounts(uint256[] calldata _newDiscounts) external onlyOwner {
        _discounts = _newDiscounts;
    }

    /*
     * change sale times
     *
     * @param _newSaleTime: new sale time
     */
    function setSaleTime(uint256 _newSaleTime) external onlyOwner {
        _saleTime = _newSaleTime;
    }

    /*
     * permanently reduce maximum supply of the collection
     *
     * @param _newMaxSupply: new maximum supply
     *
     * Error messages:
     *  - A8: "Can not increase Minotaur supply"
     *  - A9: "Can not increase Medusa supply"
     *  - A10: "Can not set the new maximum Minotaur supply under the current supply"
     *  - A11: "Can not set the new maximum Medusa supply under the current supply"
     */
    function reduceMaxSupply(
        uint256 _newMaxMinotaursSupply,
        uint256 _newMaxMedusasSupply
    ) external onlyOwner {
        require(_newMaxMinotaursSupply <= _maxSupplyMinotaurs, "A8");
        require(_newMaxMedusasSupply <= _maxSupplyMedusas, "A9");
        require(_newMaxMinotaursSupply >= totalSupply() - _numberMedusas, "A10");
        require(_newMaxMedusasSupply >= _numberMedusas, "A11");

        _maxSupplyMinotaurs = _newMaxMinotaursSupply;
        _maxSupplyMedusas = _newMaxMedusasSupply;
    }

    /*
     * get token's type
     *
     * @return isMedusa[_tokenId]: true if _tokenId is a Medusa, false if _tokenId is a Minotaur
     */
    function isTokenMedusa(uint256 _tokenId) public view returns (bool) {
        if (!_exists(_tokenId))
            _revert(IsMedusaQueryForNonexistentToken.selector);

        return isMedusa[_tokenId];
    }

    /*
     * get prices of tokens
     *
     * @return _minotaurPrice: price of the Minotaur tokens
     * @return _medusaPrice: price of the Medusa tokens
     */
    function getPrices() external view returns (uint256, uint256) {
        return (_minotaurPrice, _medusaPrice);
    }

    /*
     * get discounts
     *
     * @return _discounts: list of discounts
     */
    function getDiscounts() external view returns (uint256[] memory) {
        return (_discounts);
    }

    /*
     * get maximum supply of the collection
     *
     * @return _maxSupply: maximum supply of the collection
     */
    function getMaxSupplies() external view returns (uint256, uint256) {
        return (_maxSupplyMinotaurs, _maxSupplyMedusas);
    }

    function getTiersSupplies() external view returns (uint256, uint256) {
        return (totalSupply() - _numberMedusas, _numberMedusas);
    }

    /*
     * get time of the sale
     *
     * @return _saleTime: time of the sale
     */
    function getSaleTime() external view returns (uint256) {
        return _saleTime;
    }

    /*
     * get maximum mints per wallet for each sale type
     *
     * @return _maxMintPerWallet: maximum mint per wallet
     */
    function getMaxMintsPerWallet() external view returns (uint256) {
        return _maxMintPerWallet;
    }

    /*
     * get current number of mint of an account
     *
     * @param _account: account for which to recover the number of mints
     *
     * @return _numbMint[_account]: number of mints of _account
     */
    function getNumberOfMintPerWallet(
        address _account
    ) external view returns (uint256) {
        return _numbMint[_account];
    }

    /*
     * get the nonce of an account
     *
     * @param _account: account for which to recover the nonce
     *
     * @return nonces[_account]: nonce of _account
     */
    function getNonce(address _account) external view returns (uint256) {
        return nonces[_account];
    }

    /*
     * burn a token
     *
     * @param _tokenId: tokenId of the token to burn
     *
     * Error messages:
     *  - A12: "You don't own this token"
     */
    function burn(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "A12");

        _burn(_tokenId);
    }

    /*
     * freezes uri of tokens
     */
    function freezeMetadata() external onlyOwner {
        isUriFrozenForEver = true;
    }

    /*
     * change base URI of tokens
     *
     * Error messages:
     * - A13 : "URI has been frozen"
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        require(!isUriFrozenForEver, "A13");
        _baseTokenURI = baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (isMedusa[tokenId]) {
            return
                bytes(_baseTokenURI).length != 0
                    ? string(
                        abi.encodePacked(
                            _baseTokenURI,
                            "medusas/",
                            _toString(tokenId)
                        )
                    )
                    : "";
        }
        return
            bytes(_baseTokenURI).length != 0
                ? string(
                    abi.encodePacked(
                        _baseTokenURI,
                        "minotaurs/",
                        _toString(tokenId)
                    )
                )
                : "";
    }

    /**
     * overrides start tokenId
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * Withdraw contract's funds
     *
     * Error messages:
     * - A14 : "No shares for this account"
     * - A15 : "No remaining payment"
     */
    function withdraw(address account) external {
        require(shares[account] > 0, "A14");

        uint256 totalReceived = address(this).balance + totalReleased;
        uint256 payment = (totalReceived * shares[account]) /
            totalShares -
            released[account];

        released[account] = released[account] + payment;
        totalReleased = totalReleased + payment;

        require(payment > 0, "A15");

        payable(account).transfer(payment);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == type(IAccessControl).interfaceId;
    }
}