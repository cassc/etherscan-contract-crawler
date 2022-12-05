//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./ContractDataStorage.sol";

contract JosieNftBoxMetadata {
	using Strings for uint256;

	// Metadata image
	ContractDataStorage public contractDataStorage;

	mapping(uint256 => uint256) public revealedTokenVariant;
	string[13] public VARIANT_NAMES = [
		"Unrevealed",
		"Brainwash Victim",
		"Curb Valve",
		"Detox",
		"Galaxy Blaster",
		"Hello, My Name Is",
		"Holy Rosary",
		"King Baby",
		"Moose Sighting",
		"Pay Me",
		"Rest In Peace",
		"Unfuck The World",
		"Zoo York"
    ];

	constructor(
		address _contractDataStorageAddress
	) {
		contractDataStorage = ContractDataStorage(_contractDataStorageAddress);
	}

	/**
	 * Public functions
	 **/

	function constructTokenURI(
		uint256 _tokenId,
		uint256 _variantIdx
	)
		public
		view
	returns (
		string memory
	) {
		// Get the metadata
		bool revealed = _variantIdx > 0;
		string memory name = (revealed) ? "Don't Feed the Pigeons" : "UNREVEALED Don't Feed the Pigeons";
		string memory desc = "Hustling down a New York City street, under a sea of towering skyscrapers and kaleidoscopes of light, a gust of night air rushes through your hair as a dozen pigeons take flight around you. Their silvery gray feathers glow blue, red, and purple from the hues above. Don't they look regal?\\n\\nPigeons have a bad rep. Sure, people see them as pests now, but starting even earlier than 4500 BCE (6,500 years ago), it was a different story. Once considered a beautiful companion, pigeons were highly respected creatures. Some kept as pets, some used as mail carriers with their intelligence and navigational skills, others decorated with medals of honor for saving thousands of lives in war or stranded boats out at sea. In fact, pigeons were brought to America on the first-ever expeditions from Europe because the voyage simply couldn't be done without their help. Over the years, like a true New Yorker, they have scrappily adapted to their new environment, thriving in a concrete jungle built for mankind. Despite their fall in status, they are still as intertwined with the city as Lady Liberty. As the many signs read \\\"Don't Feed the Pigeons\\\", or do, but at least stop to appreciate the beautiful life - big and small - that creates the beating pulse of New York City.\\n\\nThe color variants of \\\"Don't Feed the Pigeons\\\" are all named after graffiti, stickers, or signs found in New York. There is a special nod hidden in the SVG layers to a very special friend. R.I.P Alotta Money, sending you love from all of the beautiful creatures here missing you.";
		string memory variant = VARIANT_NAMES[_variantIdx];

		return string(
			abi.encodePacked(
				abi.encodePacked(
					bytes('data:application/json;utf8,{"name":"'),
					name,
					bytes(' #'),
					_tokenId.toString(),
					bytes('","description":"'),
					desc,
					bytes('","image_data":"')
				),
				contractDataStorage.getData(variant),
				contractDataStorage.getData('common-bottom.svg'),
				abi.encodePacked(
					bytes('","attributes":[{"trait_type":"Variant", "value":"'),
					variant,
					bytes('"}]}')
				)
			)
		);
	}
}