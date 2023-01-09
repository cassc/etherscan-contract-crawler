// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


//Interface
interface INFTLaunchPad {
    function getBrokerage(address currency) external view returns (int256);
    function brokerAddress() external view returns (address);
    function getPublicKey() external view returns (address);
}

interface IElysianOdysseyTheGenesisV1 is IERC721 {
    function burn(uint256 tokenId) external;
}

contract ElysianOdysseyTheGenesisV2 is ERC721Enumerable, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string private constant baseURISuffix = ".json"; 
    string public constant contractURI = "https://bleufi.mypinata.cloud/ipfs/QmduhE8khJcGKYVvyoEKUsxJfygYSkTRKREWVmPkdQ6uve"; 
    address public constant creator = 0x3cd7Bd4820be8852A7d5B7BB8f5F711be3Df4024;
    uint256 public constant DECIMAL_PRECISION = 100;
    INFTLaunchPad public constant launchpad = INFTLaunchPad(0x0c80dd98D1cf3388E889Ec79c04c4B262e7f6ad9);
    IElysianOdysseyTheGenesisV1 public v1Contract = IElysianOdysseyTheGenesisV1(0xEafd42BA1d280031b5E5a421c889FbeF64b04aC1);
    
    uint256 public maxSupply = 5556; 
    uint256 public maxQuantity = 25;
    uint256 private maxNFTPerUser = 25;
    
    string private baseURI;
    mapping(uint256 => bool) public proceedNonce;
    uint256 public tokenCounter = 1561;
    
    mapping(address => uint256) public nftMinted;

    // only for interface, not used
    mapping(address => uint256) public currenciesPrice;
    mapping(address => uint256) public whitelistCurrencyPrice;
    mapping(address => bool) public currencies;
    mapping(address => bool) public whiteListCurrencies;

    
    event MintRange(address currencys, uint256 startRange, uint256 endRange);

    constructor() ERC721("Elysian Odyssey: The Genesis", "ELY") {
        _setDefaultRoyalty(0xb255ef1A56545e5527394C211463dB0913f98Cd7, 396); // 3.96%

        address[] memory _currencies = new address[](1);
        uint256[] memory _currenciesPrice = new uint256[](1);
        _currencies[0] = address(0);
        _currenciesPrice[0] = 0.1 ether;
        _setCurrency(_currencies, _currenciesPrice);
    }


    function setMaxNFTPerUser(uint256 _amount) external onlyOwner {
        maxNFTPerUser = _amount;
    }

    function setDefaultRoyalty(address _receiver, uint96 _royalties) external onlyOwner {
        _setDefaultRoyalty(_receiver, _royalties);
    }

    function setMaxQuantity(uint256 _amount) external onlyOwner {
        maxQuantity = _amount;
    }

    function setTokenCounter(uint256 tokenCounter_) external onlyOwner {
        require(tokenCounter_ > tokenCounter && tokenCounter <= maxSupply, "Invalid");
        tokenCounter = tokenCounter_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMaxSupply(uint256 _newSupply) external onlyOwner {
        require(
            _newSupply < maxSupply && _newSupply >= tokenCounter,
            "NFTCollection: Supply Should be less than Max Supply"
        );
        maxSupply = _newSupply;
    }

    function _setCurrency(
        address[] memory _currencies,
        uint256[] memory _currenciesPrice
    ) private {
        require(_currencies.length == _currenciesPrice.length);
        for (uint256 i = 0; i < _currencies.length; i++) {
            currenciesPrice[_currencies[i]] = _currenciesPrice[i];
            if (_currenciesPrice[i] == 0) {
                currencies[_currencies[i]] = true;
            }
        }
    }

    /**
     *@dev Method to set Currencies.
     *@notice Allow only authorized user to call this function.
     *@param _currencies: List of Currencies used to check currencies existence.
     *@param _currenciesPrice: List of Currencies price showing price of currency .
     */
    function setCurrency(
        address[] memory _currencies,
        uint256[] memory _currenciesPrice
    ) public onlyOwner {
        _setCurrency(_currencies, _currenciesPrice);
    }

    /**
     *@dev Method to get Brokerage.
     *@notice This method is used to get Brokerage.
     *@param _currency: address of Currency.
     */
    function _getBrokerage(address _currency) private view returns (uint256) {
        int256 _brokerage = launchpad.getBrokerage(_currency);
        require(_brokerage != 0, "NFTCollection: Currency doesn't supported.");
        if (_brokerage < 0) {
            _brokerage = 0;
        }
        return uint256(_brokerage);
    }

    /**
     *@dev Method to get Broker address
     *@return Return the address of broker
     */
    function _getBrokerAddress() private view returns (address) {
        return launchpad.brokerAddress();
    }

    function _sendNative(uint256 brokerage, uint256 _amount) private {
        if (brokerage > 0) {
            uint256 brokerageAmount = (_amount * uint256(brokerage)) /
                (100 * DECIMAL_PRECISION);
            payable(_getBrokerAddress()).transfer(brokerageAmount);
            uint256 remainingAmount = _amount - brokerageAmount;
            payable(creator).transfer(remainingAmount);
        } else {
            payable(creator).transfer(_amount);
        }
    }

    function _sendERC20(
        uint256 brokerage,
        uint256 _amount,
        address _currency
    ) private {
        IERC20 currency = IERC20(_currency);

        require(
            currency.allowance(msg.sender, address(this)) >= _amount,
            "NFTCollection: Insufficient fund allowance"
        );
        if (brokerage > 0) {
            uint256 brokerageAmount = (_amount * uint256(brokerage)) /
                (100 * DECIMAL_PRECISION);
            currency.transferFrom(
                msg.sender,
                _getBrokerAddress(),
                brokerageAmount
            );
            uint256 remainingAmount = _amount - brokerageAmount;
            currency.transferFrom(msg.sender, address(this), remainingAmount);
        } else {
            currency.transferFrom(msg.sender, address(this), _amount);
        }
    }

    function mint(
        uint256 _quantity,
        uint256 nonce,
        bytes calldata,
        bool,
        address _currency
    ) external payable nonReentrant {
        uint256 startRange = tokenCounter + 1;
        uint256 endRange = tokenCounter + _quantity;

        require(
            nftMinted[msg.sender] + _quantity <= maxNFTPerUser,
            "NFTCollection: Max limit reached"
        );

        require(!proceedNonce[nonce], "NFTCollection: Nonce already proceed!");
        require(
            _quantity > 0 && _quantity <= maxQuantity,
            "NFTCollection: Max quantity reached"
        );

        require(
            currenciesPrice[_currency] > 0 || currencies[_currency],
            "NFTCollection: Currency not Supported for public minting"
        );

        uint256 mintFee = currenciesPrice[_currency];

        if (mintFee > 0) {
            uint256 brokerage = _getBrokerage(address(_currency));
            if (address(_currency) == address(0)) {
                require(
                    msg.value >= mintFee * _quantity,
                    "NFTCollection:  amount is insufficient."
                );
                _sendNative(brokerage, msg.value);
            } else {
                _sendERC20(brokerage, mintFee * _quantity, _currency);
            }
        }

        _mintInternal(msg.sender, _quantity);

        nftMinted[msg.sender] += _quantity;
        proceedNonce[nonce] = true;
        emit MintRange(_currency, startRange, endRange);
    }

    function mintFor(address _to, uint256 _quantity) external payable nonReentrant {
        require(
            nftMinted[_to] + _quantity <= maxNFTPerUser,
            "NFTCollection: Max limit reached"
        );

        require(
            _quantity > 0 && _quantity <= maxQuantity,
            "NFTCollection: Max quantity reached"
        );

        uint256 mintFee = currenciesPrice[address(0)];
        require(
            msg.value >= mintFee * _quantity,
            "NFTCollection: amount is insufficient."
        );

        payable(creator).transfer(msg.value);

        _mintInternal(_to, _quantity);
        nftMinted[_to] += _quantity;
    }

    function migrate(address user, uint256[] calldata tokenIds) external nonReentrant {
        nftMinted[user] += tokenIds.length;
        
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            v1Contract.transferFrom(user, address(this), tokenIds[i]);
            v1Contract.burn(tokenIds[i]);
            if (_exists(tokenIds[i])) {
                _transfer(address(this), user, tokenIds[i]);
            } else {
                _safeMint(user, tokenIds[i]);
            }
        }
    }

    function premintMigration(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _mint(address(this), tokenIds[i]);
        }
    }

    /**
     *@dev Method to mint by only owner.
     *@notice This method will allow onlyOwner to mint.
     *@param _quantity: NFT quantity to be minted.
     */
    function mintByOwner(uint256 _quantity) external onlyOwner {
        _mintInternal(msg.sender, _quantity);
    }

    
    function mintTokenIdsByOwner(address[] calldata _recipients, uint256[][] calldata _tokenIds) external onlyOwner {
        require(_recipients.length != 0, "invalid length");
        require(_recipients.length == _tokenIds.length, "length missmatch");
        for (uint256 i = 0; i < _recipients.length; ++i) {
            require(_tokenIds.length != 0, "invalid length");
            for (uint256 j = 0; j < _tokenIds[i].length; ++j) {
                require(_tokenIds[i][j] <= tokenCounter, "mintable");
                require(_v1DoesNotExist(_tokenIds[i][j]), "v1 tokenId still exists");
                _safeMint(_recipients[i], _tokenIds[i][j]);
            }
            nftMinted[_recipients[i]] += _tokenIds[i].length;
        }
    }

    /**
     *@dev Method to withdraw ERC20 token.
     *@notice This method will allow only owner to withdraw ERC20 token.
     *@param _receiver: address of receiver
     */
    function withdrawERC20Token(address _receiver, address _currency)
        external
        onlyOwner
    {
        IERC20 currency = IERC20(_currency);
        require(
            currency.balanceOf(address(this)) > 0,
            "NFTCollection: Insufficient fund"
        );
        currency.transfer(_receiver, currency.balanceOf(address(this)));
    }

    /**
     *@dev Method to withdraw native currency.
     *@notice This method will allow only owner to withdraw currency.
     *@param _receiver: address of receiver
     */

    function withdrawBNB(address _receiver) external onlyOwner {
        payable(_receiver).transfer(address(this).balance);
    }

    function _mintInternal(address _to, uint256 _quantity) internal {
        require(
            tokenCounter + _quantity <= maxSupply,
            "NFTCollection: Max supply must be greater!"
        );

        for (uint256 i = 1; i <= _quantity; ++i) {
            _safeMint(_to, tokenCounter + i);
        }
        tokenCounter += _quantity;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _baseURISuffix() internal view virtual returns (string memory) {
        return baseURISuffix;
    }

    function _v1DoesNotExist(uint256 tokenId) internal view returns (bool) {
        try v1Contract.ownerOf(tokenId) returns (address) {
            return false;
        } catch Error(string memory) {
            return true;
        } catch (bytes memory) {
            return true;
        }
    }

    function price() external view returns (uint256) {
        return currenciesPrice[address(0)];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert("TokenId does not exist");

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), baseURISuffix))
                : "";
    }
}