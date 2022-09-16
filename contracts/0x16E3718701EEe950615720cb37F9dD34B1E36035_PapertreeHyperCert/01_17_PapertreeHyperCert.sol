// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./HyperCert.sol";
import "./utils/HyperCertSVG.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PapertreeHyperCert is HyperCert, Ownable {
    using Counters for Counters.Counter;
	Counters.Counter private _tokenIdCounter;

    mapping(address => uint256) private _totalBalance;
    mapping(uint256 => address) private _ownerByIndex;

	constructor() HyperCert(
		"https://api.papertree.earth/v1/tokens/{id}",
		"https://api.papertree.earth/v1/claims/{id}") {}

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalBalance(address account) public view returns (uint256) {
        return _totalBalance[account];
    }

    /**
     * @dev Get Owner By Index
     */
    function ownerOf(uint256 id) public view returns (address) {
        return _ownerByIndex[id];
    }

    function incrementCounter() public onlyOwner returns (uint256) {
    	_tokenIdCounter.increment();
    	return _tokenIdCounter.current();
    }
	
	function mintItem(
		address to, 
		uint256 amount, 
		uint256 unitsOfPublicGoodsSpace) 
	public returns (uint256) {
        _tokenIdCounter.increment();
        mint(to, _tokenIdCounter.current(), amount, unitsOfPublicGoodsSpace, _asManyArray(_msgSender(), 1));
        return _tokenIdCounter.current();
    }

	function mint(
		address to,
		uint256 id,
		uint256 amount,
		uint256 unitsOfPublicGoodsSpace,
		address[] memory contributors_
	) public override onlyOwner {
		super.mint(to, id, amount, unitsOfPublicGoodsSpace, contributors_);
	}

	function mintBatch(
		address to,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		uint256[] calldata unitsOfPublicGoodsSpace,
		address[][] calldata contributors_
	) public override onlyOwner {
		super.mintBatch(to, ids, amounts, unitsOfPublicGoodsSpace, contributors_);
	}

	function uri(uint256 _tokenId) public view override returns (string memory) {
		string memory sClaims_;
		uint256 units = 0;
		for (uint256 i = 0; i < claimsOf(_ownerByIndex[_tokenId], _tokenId).length; i++) {
			sClaims_ = string.concat(sClaims_, "#", Strings.toString(claimsOf(_ownerByIndex[_tokenId], _tokenId)[i]), " ");
			units += 1;
		}

		string memory svg = Base64.encode(
			bytes(
				abi.encodePacked(
					HyperCertSVG.svg_begin(),
					sClaims_,
					"</text><text transform='translate(98.126 317.35)' font-size='8' fill='#020403' font-family='Tangerine, Tangerine'>#",
					Strings.toString(_tokenId),
					"</text><text x='269.2915' y='240.94' text-anchor='middle' font-size='12' fill='#020403' font-family='Tangerine, Tangerine'>",
					Strings.toHexString(_ownerByIndex[_tokenId]),
					"</text></g><defs><radialGradient id='paint0_radial_1_814' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(269.292 192.485) scale(287.707 287.707)'><stop stop-color='white'/><stop offset='1' stop-color='#B1BDDC'/></radialGradient><linearGradient id='paint1_linear_1_814' x1='331.811' y1='42.048' x2='289.382' y2='41.307' gradientUnits='userSpaceOnUse'><stop stop-color='#00261B'/><stop offset='0.39' stop-color='#C2D0C5'/><stop offset='0.66' stop-color='#D5DDD5'/><stop offset='1' stop-color='#00261B'/></linearGradient><linearGradient id='paint2_linear_1_814' x1='328.666' y1='41.717' x2='291.446' y2='41.717' gradientUnits='userSpaceOnUse'><stop stop-color='#3266E8'/><stop offset='0.33' stop-color='#6E8AD2'/><stop offset='0.74' stop-color='#9CB2EB'/><stop offset='1' stop-color='#000426'/></linearGradient><linearGradient id='paint3_linear_1_814' x1='210.377' y1='40.9971' x2='247.596' y2='41.199' gradientUnits='userSpaceOnUse'><stop stop-color='#3266E8'/><stop offset='0.33' stop-color='#6E8AD2'/><stop offset='0.74' stop-color='#9CB2EB'/><stop offset='1' stop-color='#000426'/></linearGradient><linearGradient id='paint4_linear_1_814' x1='325.852' y1='36.608' x2='181.824' y2='36.608' gradientUnits='userSpaceOnUse'><stop stop-color='#9CB2EB'/><stop offset='0.15' stop-color='#3266E8'/><stop offset='0.34' stop-color='#9CB2EB'/><stop offset='0.5' stop-color='#3266E8'/><stop offset='0.73' stop-color='#9CB2EB'/><stop offset='0.92' stop-color='#3266E8'/><stop offset='1' stop-color='#9CB2EB'/></linearGradient><clipPath id='clip0_1_814'><rect width='538.583' height='384.97' fill='white'/></clipPath></defs></svg>"
				)
			)
		);

		// prettier-ignore
		/* solhint-disable */
		string memory json = string(abi.encodePacked(
			'{ "id": ',
			Strings.toString(_tokenId),
			', "metaDataUrl": "',
			'https://api.papertree.earth/v1/tokens/',
			Strings.toString(_tokenId),
			'",  "image": "data:image/svg+xml;base64,',
			svg,
			'" }'
			));

		// prettier-ignore
		return string(abi.encodePacked('data:application/json;utf8,', json));
		/* solhint-enable */
	}

	function claimsUri(uint256 _claimid) override public pure returns (string memory) {
		return string(
			abi.encodePacked(
				"https://api.papertree.earth/v1/claims/",
				Strings.toString(_claimid)
			)
		);
	}

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (to != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalBalance[to] += amounts[i];
                _ownerByIndex[ids[i]] = to;
            }
        }

        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                unchecked {
                    _totalBalance[from] = _totalBalance[from] - amounts[i];
                }
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                delete _ownerByIndex[ids[i]];
            }
    	}
    }

  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}

}