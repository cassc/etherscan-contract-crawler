// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @author Brewlabs
 * This contract has been developed by brewlabs.info
 */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721, ERC721Enumerable, IERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract SpriteOnsenNft is Ownable, ERC721Enumerable, ReentrancyGuard, DefaultOperatorFilterer {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    uint256 private constant MAX_SUPPLY = 5000;
    bool public mintAllowed = false;

    string private _tokenBaseURI = "";
    uint256 public oneTimeMintLimit = 10;

    address public feeWallet;
    IERC20 public feeToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    uint256 public mintPrice = 1000 * 10 ** 6;

    uint256 public materialSaleTime = 1685620800;
    IERC20[] public materialTokens;
    uint256[] public materialPrices;

    event MintEnabled();
    event MoveToNextPhase(uint256 phase);
    event Mint(address indexed user, uint256 tokenId);
    event BaseURIUpdated(string uri);

    event SetMintPrice(uint256 price);
    event SetFeeToken(address token);
    event SetOneTimeMintLimit(uint256 limit);

    event SetFeeWallet(address wallet);
    event SetMaterialSaleTime(uint256 timestamp);
    event SetMaterialToken(uint256 index, address indexed token, uint256 price);
    event RemoveMaterialToken(address indexed token);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);

    modifier onlyMintable() {
        require(mintAllowed && totalSupply() < MAX_SUPPLY, "cannot mint");
        _;
    }

    constructor() ERC721("Sprite Onsen Pass", "SOP") {
        feeWallet = msg.sender;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override (ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override (ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override (ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override (ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override (ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function mint(uint256 _numToMint) external onlyMintable nonReentrant {
        require(_numToMint > 0, "invalid amount");
        require(_numToMint <= oneTimeMintLimit, "exceed one-time mint limit");
        require(
            (totalSupply() + _numToMint <= 200 && block.timestamp < materialSaleTime)
                || (totalSupply() + _numToMint <= MAX_SUPPLY && block.timestamp >= materialSaleTime),
            "Exceed current phase limit"
        );

        uint256 price = mintPrice * _numToMint;
        feeToken.safeTransferFrom(msg.sender, feeWallet, price);
        if (block.timestamp >= materialSaleTime) {
            for (uint256 i = 0; i < materialTokens.length; i++) {
                uint256 amount = materialPrices[i] * _numToMint;
                materialTokens[i].safeTransferFrom(msg.sender, feeWallet, amount);
            }
        }

        for (uint256 i = 0; i < _numToMint; i++) {
            uint256 tokenId = totalSupply() + 1;

            _safeMint(msg.sender, tokenId);
            emit Mint(msg.sender, tokenId);
        }

        if (totalSupply() == MAX_SUPPLY) mintAllowed = false;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "SpriteOnsenNft: URI query for nonexistent token");

        string memory base = _baseURI();
        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                name(),
                " #",
                tokenId.toString(),
                '", "description": "Sprite Onsen Pass holders gain exclusive access to the first AI NFT yield earning protocol in defi.", ',
                '"image":"',
                base,
                '", "attributes":[{"trait_type":"Pass Type", "value":"Ordinary"}]}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", _base64(bytes(metadata))));
    }

    function materialTokenCount() external view returns (uint256) {
        return materialTokens.length;
    }

    function enableMint() external onlyOwner {
        require(!mintAllowed, "already enabled");

        mintAllowed = true;
        emit MintEnabled();
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
        emit SetMintPrice(_price);
    }

    function setFeeToken(address _token) external onlyOwner {
        require(_token != address(0x0), "invalid token");
        require(_token != address(feeToken), "already set");
        require(!mintAllowed, "mint was enabled");

        feeToken = IERC20(_token);
        emit SetFeeToken(_token);
    }

    function setMaterialSaleTime(uint256 _timestamp) external onlyOwner {
        require(block.timestamp < materialSaleTime, "already started");
        require(block.timestamp < _timestamp, "can set only upcoming timestamp");
        materialSaleTime = _timestamp;
        emit SetMaterialSaleTime(_timestamp);
    }

    function addMaterialTokens(IERC20[] memory _tokens, uint256[] memory _prices) external onlyOwner {
        require(_tokens.length == _prices.length, "mismatch tokens and prices");
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(!_tokenExists(_tokens[i], materialTokens.length), "token already taken");

            materialTokens.push(_tokens[i]);
            materialPrices.push(_prices[i]);
            emit SetMaterialToken(materialTokens.length - 1, address(_tokens[i]), _prices[i]);
        }
    }

    function setMaterialToken(uint256 _index, IERC20 _token, uint256 _price) external onlyOwner {
        require(_index < materialTokens.length, "invalid index");
        require(!_tokenExists(_token, _index), "token already taken");

        materialTokens[_index] = _token;
        materialPrices[_index] = _price;
        emit SetMaterialToken(_index, address(_token), _price);
    }

    function removeMaterialToken(uint256 _index) external onlyOwner {
        require(_index < materialTokens.length, "invalid index");

        address _token = address(materialTokens[_index]);

        materialTokens[_index] = materialTokens[materialTokens.length - 1];
        materialPrices[_index] = materialPrices[materialTokens.length - 1];
        materialTokens.pop();
        materialPrices.pop();

        emit RemoveMaterialToken(_token);
    }

    function setOneTimeMintLimit(uint256 _limit) external onlyOwner {
        require(_limit <= 150, "cannot exceed 150");
        oneTimeMintLimit = _limit;
        emit SetOneTimeMintLimit(_limit);
    }

    function setAdminWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0x0), "invalid address");
        feeWallet = _wallet;
        emit SetFeeWallet(_wallet);
    }

    function rescueTokens(address _token, uint256 _amount) external onlyOwner {
        if (_token == address(0x0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_token).transfer(address(msg.sender), _amount);
        }

        emit AdminTokenRecovered(_token, _amount);
    }

    function setTokenBaseUri(string memory _uri) external onlyOwner {
        _tokenBaseURI = _uri;
        emit BaseURIUpdated(_uri);
    }

    function _tokenExists(IERC20 _token, uint256 _index) internal view returns (bool) {
        for (uint256 i = 0; i < materialTokens.length; i++) {
            if (i != _index && materialTokens[i] == _token) return true;
        }

        return false;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function _base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {} {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    receive() external payable {}
}