// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;
import "./openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./openzeppelin/contracts/access/Ownable.sol";
import "./openzeppelin/contracts/utils/math/SafeMath.sol";
import "./openzeppelin/contracts/utils/Address.sol";
import "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

contract RugstoreIO is Ownable, ERC721Enumerable {
  using SafeMath for uint256;
  using Strings for uint256;
  uint public constant max_supply = 3333;
  IQuoter public constant quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
  address private constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address private constant pebble = 0xDC98c5543F3004DEBfaad8966ec403093D0aa4A8;
  address public constant weaver = 0x500c579764fA743c49392293086D53632817bC25;
  uint256 public pebblePrice;
  uint256 _pebble;
  uint256 public constant ethprice = 12500000000000000;
  uint256 public constant mintprice = 25000000000000000;
  uint[] public priceDog;
  uint[] public priceAgld;
  uint[] public priceAsh;
  IERC20 DOG=IERC20(0xBAac2B4491727D78D2b78815144570b9f2Fe8899);
  IERC20 PEBBLE=IERC20(0xDC98c5543F3004DEBfaad8966ec403093D0aa4A8);
  IERC20 ASH=IERC20(0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92);
  IERC20 AGLD=IERC20(0x32353A6C91143bfd6C7d363B546e62a9A2489A20);
  bool public isActive = false;
  mapping (uint256 => string) private _tokenURIs;
  string private _baseURIextended;

  constructor() ERC721("Rugstore", "RUG") { }

    function rug() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
      }
      function balanceEth() public view returns(uint256) {
          uint balance = address(this).balance;
          return balance;
        }


    function initializeRug() public onlyOwner {
      isActive = !isActive;
      for(uint i = 0; i < 3; i++) {
          uint mintIndex = totalSupply();
          if (totalSupply() < max_supply) {
              _safeMint(msg.sender, mintIndex);
          }
      }
    }

    //BASEURI STUFF
        function setBaseURI(string memory baseURI_) external onlyOwner() {
            _baseURIextended = baseURI_;
        }

        function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
            require(_exists(tokenId));
            _tokenURIs[tokenId] = _tokenURI;
        }

        function _baseURI() internal view virtual override returns (string memory) {
            return _baseURIextended;
        }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId));

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        string memory json = ".json";

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI, json));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString(), json));
    }
    function mintRugWithEth(uint numberOfTokens) public payable {
        require(isActive);
        require(numberOfTokens > 0 && numberOfTokens <= 25);
        require(totalSupply().add(numberOfTokens) <= max_supply);
        require(msg.value >= mintprice.mul(numberOfTokens));

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < max_supply) {
                _safeMint(msg.sender, mintIndex);
            }
        }

      }

      function mintRugWithDog(uint numberOfTokens) public {
          require(isActive);
          require(numberOfTokens > 0 && numberOfTokens <= 15);
          require(totalSupply() < max_supply);
          DOG.transferFrom(msg.sender, weaver, priceDog[1].mul(numberOfTokens));
          for(uint i = 0; i < numberOfTokens; i++) {
              uint mintIndex = totalSupply();
              if (totalSupply() < max_supply) {
                  _safeMint(msg.sender, mintIndex);
              }
          }

        }
        function mintRugWithAgld(uint numberOfTokens) public {
            require(isActive);
            require(numberOfTokens > 0 && numberOfTokens <= 15);
            require(totalSupply() < max_supply);
            AGLD.transferFrom(msg.sender, weaver, priceAgld[1].mul(numberOfTokens));
            for(uint i = 0; i < numberOfTokens; i++) {
                uint mintIndex = totalSupply();
                if (totalSupply() < max_supply) {
                    _safeMint(msg.sender, mintIndex);
                }
            }

          }
          function mintRugWithAsh(uint numberOfTokens) public {
              require(isActive);
              require(numberOfTokens > 0 && numberOfTokens <= 15);
              require(totalSupply() < max_supply);
              ASH.transferFrom(msg.sender, weaver, priceAsh[1].mul(numberOfTokens));
              for(uint i = 0; i < numberOfTokens; i++) {
                  uint mintIndex = totalSupply();
                  if (totalSupply() < max_supply) {
                      _safeMint(msg.sender, mintIndex);
                  }
              }

            }
            function mintRugWithPebble(uint numberOfTokens) public {
                require(isActive);
                require(numberOfTokens > 0 && numberOfTokens <= 15);
                require(totalSupply() < max_supply);
                PEBBLE.transferFrom(msg.sender, weaver, pebblePrice.mul(numberOfTokens));
                for(uint i = 0; i < numberOfTokens; i++) {
                    uint mintIndex = totalSupply();
                    if (totalSupply() < max_supply) {
                        _safeMint(msg.sender, mintIndex);
                    }
                }

              }

        function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
            uint256 tokenCount = balanceOf(_owner);
            if (tokenCount == 0) {
                // Return an empty array
                return new uint256[](0);
            } else {
                uint256[] memory result = new uint256[](tokenCount);
                uint256 index;
                for (index = 0; index < tokenCount; index++) {
                    result[index] = tokenOfOwnerByIndex(_owner, index);
                }
                return result;
            }
        }

        function getDogPriceSushi(uint _eth_amount) public view returns(uint[] memory amount) {
            address[] memory path = new address[](2);
            path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            path[1] = 0xBAac2B4491727D78D2b78815144570b9f2Fe8899;

            uint256[] memory result = SushiV2.getAmountsOut(_eth_amount, path);
            return result;
        }
        function getAGLDPriceSushi(uint _eth_amount) public view returns(uint[] memory amount) {
            address[] memory path = new address[](2);
            path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            path[1] = 0x32353A6C91143bfd6C7d363B546e62a9A2489A20;

            uint256[] memory result = SushiV2.getAmountsOut(_eth_amount, path);
            return result;
        }
        function getASHPriceUNI(uint _eth_amount) public view returns(uint[] memory amount) {
            address[] memory path = new address[](2);
            path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            path[1] = 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92;

            uint256[] memory result = UniV2.getAmountsOut(_eth_amount, path);
            return result;
        }
        function showDogPriceSushi() public view returns(uint256) {
          return priceDog[1];
        }
        function showASHPriceUNI() public view returns(uint256) {
          return priceAsh[1];
        }
        function showAGLDPriceSushi() public view returns(uint256) {
          return priceAgld[1];
        }

        function setPriceDog() public {
          priceDog = getDogPriceSushi(12500000000000000);
        }
        function setPriceAGLD() public {
          priceAgld = getAGLDPriceSushi(12500000000000000);
        }
        function setPriceASH() public {
          priceAsh = getASHPriceUNI(12500000000000000);
        }


        function setPrices() public {
          priceDog = getDogPriceSushi(12500000000000000);
          priceAgld = getAGLDPriceSushi(12500000000000000);
          priceAsh = getASHPriceUNI(12500000000000000);
          _pebble = getEstimatedPebbleforEth(1);
          pebblePrice = ethprice * _pebble;
        }


        function setPebblePrice() public {
        _pebble = getEstimatedPebbleforEth(1);
        pebblePrice = ethprice * _pebble;

        }
        function showPebblePrice() public view returns(uint256) {
        return pebblePrice;
        }
        //using sushiv2
        UniswapRouter SushiV2 = UniswapRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
        //uni-v2
        UniswapRouter UniV2 = UniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        /*@dev get AGLD price via UNI-V3
        */
        function getEstimatedPebbleforEth(uint uniAmount) public payable returns (uint256) {
          address tokenIn = pebble;
          address tokenOut = WETH9;
          uint24 fee = 10000;
          uint160 sqrtPriceLimitX96 = 0;

          return quoter.quoteExactOutputSingle(
              tokenIn,
              tokenOut,
              fee,
              uniAmount,
              sqrtPriceLimitX96
          );
        }
  }
  interface UniswapRouter {
      function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  }