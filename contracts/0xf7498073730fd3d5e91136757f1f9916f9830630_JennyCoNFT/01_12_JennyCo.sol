// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract JennyCoNFT is ERC721, Ownable {
    using Address for address;

    uint256 public mintPrice = 0.15 ether;

    uint256 private tokenIDPointer = 1;
    uint256 public totalSupply = 920;
    uint256 public totalMinted = 0;

    bool public isMintEnabled = false;
    bool public isRevealed = false;

    string public baseUri = "";

    mapping(address => uint256[]) public holdings;

    mapping(address => bool) public minted;
    mapping(uint256 => bool) public dnaTested;

    modifier isMintable() {
        require(isMintEnabled, "mint hasn't started yet");
        require(msg.value >= mintPrice, "insuffcient fund!");
        require(!minted[msg.sender], "can mint only 1 nft!");
        require(totalSupply > tokenIDPointer, "mint completed!");
        _;
    }

    event Minted(address indexed minter, uint256 tokenID);

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function mint() external payable isMintable {
        uint256 tokenID = _getNewTokenIDPointer();
        _mint(msg.sender, tokenID);
        _increaseTokenIDPointer();
        totalMinted += 1;
        minted[msg.sender] = true;
        emit Minted(msg.sender, tokenID);
    }

    function enableMint() external onlyOwner {
        require(!isMintEnabled, "mint already started!");
        isMintEnabled = true;
    }

    function reveal() external onlyOwner {
        require(!isRevealed, "already revealed");
        isRevealed = true;
    }

    function setBaseUri(string calldata _uri) external onlyOwner {
        baseUri = _uri;
    }

    function testDNA(uint256 tokenID) public {
        address owner = ownerOf(tokenID);
        require(owner == msg.sender, "unauthorised!");
        require(!dnaTested[tokenID], "already tested!");
        dnaTested[tokenID] = true;
    }

    function getMyNFTs(address holder)
        public
        view
        returns (uint256[] memory _mine)
    {
        _mine = holdings[holder];
    }

    function tokenURI(uint256 tokenID)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenID),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (!isRevealed) return "https://www.jennyco.io/";
        else
            return
                bytes(baseUri).length > 0
                    ? string(
                        abi.encodePacked(
                            baseUri,
                            Strings.toString(tokenID),
                            ".json"
                        )
                    )
                    : "";
    }

    function withdraw(address to) external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "ether transfer failed");
    }

    function rescueToken(address _token, address to) external onlyOwner {
        require(
            IERC20(_token).transfer(to, IERC20(_token).balanceOf(address(this)))
        );
    }

    function _increaseTokenIDPointer() private {
        tokenIDPointer += 1;
    }

    function _getNewTokenIDPointer() private view returns (uint256) {
        return tokenIDPointer;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from != address(0)) {
            uint256[] memory fromHoldings = holdings[from];
            uint256 fromIndex = 0;
            uint256 fromLength = fromHoldings.length;
            for (uint256 i = 0; i < fromLength; ++i) {
                if (tokenId == fromHoldings[i]) {
                    fromIndex = i;
                    break;
                }
            }
            uint256 tmp = fromHoldings[fromLength - 1];
            fromHoldings[fromIndex] = tmp;
            fromHoldings[fromLength - 1] = tokenId;
            delete fromHoldings[fromLength - 1];

            if (fromLength == 1) {
                uint256[] memory _newFromHoldings = new uint256[](0);
                holdings[from] = _newFromHoldings;
            } else {
                uint256[] memory _newFromHoldings = new uint256[](
                    fromLength - 1
                );
                for (uint256 i = 0; i < fromLength - 1; ++i)
                    _newFromHoldings[i] = fromHoldings[i];
                holdings[from] = _newFromHoldings;
            }
        }

        if (to != address(0)) {
            uint256[] memory toHoldings = holdings[to];
            uint256 toLength = toHoldings.length;
            uint256[] memory _newToHoldings = new uint256[](toLength + 1);
            for (uint256 i = 0; i < toLength; ++i) {
                _newToHoldings[i] = toHoldings[i];
            }
            _newToHoldings[toLength] = tokenId;
            holdings[to] = _newToHoldings;
        }
    }

    receive() external payable {}
}