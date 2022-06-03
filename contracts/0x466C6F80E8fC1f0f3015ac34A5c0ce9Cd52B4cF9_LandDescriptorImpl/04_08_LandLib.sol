// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Land Library
 *
 * @notice A library defining data structures related to land plots (used in Land ERC721 token),
 *      and functions transforming these structures between view and internal (packed) representations,
 *      in both directions.
 *
 * @notice Due to some limitations Solidity has (ex.: allocating array of structures in storage),
 *      and due to the specific nature of internal land structure
 *      (landmark and resource sites data is deterministically derived from a pseudo random seed),
 *      it is convenient to separate data structures used to store metadata on-chain (store),
 *      and data structures used to present metadata via smart contract ABI (view)
 *
 * @notice Introduces helper functions to detect and deal with the resource site collisions
 *
 * @author Basil Gorin
 */
library LandLib {
	/**
	 * @title Resource Site View
	 *
	 * @notice Resource Site, bound to a coordinates (x, y) within the land plot
	 *
	 * @notice Resources can be of two major types, each type having three subtypes:
	 *      - Element (Carbon, Silicon, Hydrogen), or
	 *      - Fuel (Crypton, Hyperion, Solon)
	 *
	 * @dev View only structure, used in public API/ABI, not used in on-chain storage
	 */
	struct Site {
		/**
		 * @dev Site type:
		 *        1) Carbon (element),
		 *        2) Silicon (element),
		 *        3) Hydrogen (element),
		 *        4) Crypton (fuel),
		 *        5) Hyperion (fuel),
		 *        6) Solon (fuel)
		 */
		uint8 typeId;

		/**
		 * @dev x-coordinate within a plot
		 */
		uint16 x;

		/**
		 * @dev y-coordinate within a plot
		 */
		uint16 y;
	}

	/**
	 * @title Land Plot View
	 *
	 * @notice Land Plot, bound to a coordinates (x, y) within the region,
	 *      with a rarity defined by the tier ID, sites, and (optionally)
	 *      a landmark, positioned on the internal coordinate grid of the
	 *      specified size within a plot.
	 *
	 * @notice Land plot coordinates and rarity are predefined (stored off-chain).
	 *      Number of sites (and landmarks - 0/1) is defined by the land rarity.
	 *      Positions of sites, types of sites/landmark are randomized and determined
	 *      upon land plot creation.
	 *
	 * @dev View only structure, used in public API/ABI, not used in on-chain storage
	 */
	struct PlotView {
		/**
		 * @dev Region ID defines the region on the map in IZ:
		 *        1) Abyssal Basin
		 *        2) Brightland Steppes
		 *        3) Shardbluff Labyrinth
		 *        4) Crimson Waste
		 *        5) Halcyon Sea
		 *        6) Taiga Boreal
		 *        7) Crystal Shores
		 */
		uint8 regionId;

		/**
		 * @dev x-coordinate within the region
		 */
		uint16 x;

		/**
		 * @dev y-coordinate within the region
		 */
		uint16 y;

		/**
		 * @dev Tier ID defines land rarity and number of sites within the plot
		 */
		uint8 tierId;

		/**
		 * @dev Plot size, limits the (x, y) coordinates for the sites
		 */
		uint16 size;

		/**
		 * @dev Landmark Type ID:
		 *        0) no Landmark
		 *        1) Carbon Landmark,
		 *        2) Silicon Landmark,
		 *        3) Hydrogen Landmark (Eternal Spring),
		 *        4) Crypton Landmark,
		 *        5) Hyperion Landmark,
		 *        6) Solon Landmark (Fallen Star),
		 *        7) Arena
		 *
		 * @dev Landmark is always positioned in the center of internal grid
		 */
		uint8 landmarkTypeId;

		/**
		 * @dev Number of Element Sites (Carbon, Silicon, or Hydrogen) this plot contains,
		 *      matches the number of element sites in sites[] array
		 */
		uint8 elementSites;

		/**
		 * @dev Number of Fuel Sites (Crypton, Hyperion, or Solon) this plot contains,
		 *      matches the number of fuel sites in sites[] array
		 */
		uint8 fuelSites;

		/**
		 * @dev Element/fuel sites within the plot
		 */
		Site[] sites;
	}

	/**
	 * @title Land Plot Store
	 *
	 * @notice Land Plot data structure as it is stored on-chain
	 *
	 * @notice Contains the data required to generate `PlotView` structure:
	 *      - regionId, x, y, tierId, size, landmarkTypeId, elementSites, and fuelSites are copied as is
	 *      - version and seed are used to derive array of sites (together with elementSites, and fuelSites)
	 *
	 * @dev On-chain optimized structure, has limited usage in public API/ABI
	 */
	struct PlotStore {
		/**
		 * @dev Generator Version, reserved for the future use in order to tweak the
		 *      behavior of the internal land structure algorithm
		 */
		uint8 version;

		/**
		 * @dev Region ID defines the region on the map in IZ:
		 *        1) Abyssal Basin
		 *        2) Brightland Steppes
		 *        3) Shardbluff Labyrinth
		 *        4) Crimson Waste
		 *        5) Halcyon Sea
		 *        6) Taiga Boreal
		 *        7) Crystal Shores
		 */
		uint8 regionId;

		/**
		 * @dev x-coordinate within the region
		 */
		uint16 x;

		/**
		 * @dev y-coordinate within the region
		 */
		uint16 y;

		/**
		 * @dev Tier ID defines land rarity and number of sites within the plot
		 */
		uint8 tierId;

		/**
		 * @dev Plot Size, limits the (x, y) coordinates for the sites
		 */
		uint16 size;

		/**
		 * @dev Landmark Type ID:
		 *        0) no Landmark
		 *        1) Carbon Landmark,
		 *        2) Silicon Landmark,
		 *        3) Hydrogen Landmark (Eternal Spring),
		 *        4) Crypton Landmark,
		 *        5) Hyperion Landmark,
		 *        6) Solon Landmark (Fallen Star),
		 *        7) Arena
		 *
		 * @dev Landmark is always positioned in the center of internal grid
		 */
		uint8 landmarkTypeId;

		/**
		 * @dev Number of Element Sites (Carbon, Silicon, or Hydrogen) this plot contains
		 */
		uint8 elementSites;

		/**
		 * @dev Number of Fuel Sites (Crypton, Hyperion, or Solon) this plot contains
		 */
		uint8 fuelSites;

		/**
		 * @dev Pseudo-random Seed to generate Internal Land Structure,
		 *      should be treated as already used to derive Landmark Type ID
		 */
		uint160 seed;
	}

	/**
	 * @dev Tightly packs `PlotStore` data struct into uint256 representation
	 *
	 * @param store `PlotStore` data struct to pack
	 * @return packed `PlotStore` data struct packed into uint256
	 */
	function pack(PlotStore memory store) internal pure returns (uint256 packed) {
		return uint256(store.version) << 248
			| uint248(store.regionId) << 240
			| uint240(store.x) << 224
			| uint224(store.y) << 208
			| uint208(store.tierId) << 200
			| uint200(store.size) << 184
			| uint184(store.landmarkTypeId) << 176
			| uint176(store.elementSites) << 168
			| uint168(store.fuelSites) << 160
			| uint160(store.seed);
	}

	/**
	 * @dev Unpacks `PlotStore` data struct from uint256 representation
	 *
	 * @param packed uint256 packed `PlotStore` data struct
	 * @return store unpacked `PlotStore` data struct
	 */
	function unpack(uint256 packed) internal pure returns (PlotStore memory store) {
		return PlotStore({
			version:        uint8(packed >> 248),
			regionId:       uint8(packed >> 240),
			x:              uint16(packed >> 224),
			y:              uint16(packed >> 208),
			tierId:         uint8(packed >> 200),
			size:           uint16(packed >> 184),
			landmarkTypeId: uint8(packed >> 176),
			elementSites:   uint8(packed >> 168),
			fuelSites:      uint8(packed >> 160),
			seed:           uint160(packed)
		});
	}

	/**
	 * @dev Expands `PlotStore` data struct into a `PlotView` view struct
	 *
	 * @dev Derives internal land structure (resource sites the plot has)
	 *      from Number of Element/Fuel Sites, Plot Size, and Seed;
	 *      Generator Version is not currently used
	 *
	 * @param store on-chain `PlotStore` data structure to expand
	 * @return `PlotView` view struct, expanded from the on-chain data
	 */
	function plotView(PlotStore memory store) internal pure returns (PlotView memory) {
		// copy most of the fields as is, derive resource sites array inline
		return PlotView({
			regionId:       store.regionId,
			x:              store.x,
			y:              store.y,
			tierId:         store.tierId,
			size:           store.size,
			landmarkTypeId: store.landmarkTypeId,
			elementSites:   store.elementSites,
			fuelSites:      store.fuelSites,
			// derive the resource sites from Number of Element/Fuel Sites, Plot Size, and Seed
			sites:          getResourceSites(store.seed, store.elementSites, store.fuelSites, store.size, 2)
		});
	}

	/**
	 * @dev Based on the random seed, tier ID, and plot size, determines the
	 *      internal land structure (resource sites the plot has)
	 *
	 * @dev Function works in a deterministic way and derives the same data
	 *      for the same inputs; the term "random" in comments means "pseudo-random"
	 *
	 * @param seed random seed to consume and derive the internal structure
	 * @param elementSites number of element sites plot has
	 * @param fuelSites number of fuel sites plot has
	 * @param gridSize plot size `N` of the land plot to derive internal structure for
	 * @param siteSize implied size `n` of the resource sites
	 * @return sites randomized array of resource sites
	 */
	function getResourceSites(
		uint256 seed,
		uint8 elementSites,
		uint8 fuelSites,
		uint16 gridSize,
		uint8 siteSize
	) internal pure returns (Site[] memory sites) {
		// derive the total number of sites
		uint8 totalSites = elementSites + fuelSites;

		// denote the grid (plot) size `N`
		// denote the resource site size `n`

		// transform coordinate system (1): normalization (x, y) => (x / n, y / n)
		// if `N` is odd this cuts off border coordinates x = N - 1, y = N - 1
		uint16 normalizedSize = gridSize / siteSize;

		// after normalization (1) is applied, isomorphic grid becomes effectively larger
		// due to borders capturing effect, for example if N = 4, and n = 2:
		//      | .. |                                              |....|
		// grid |....| becomes |..| normalized which is effectively |....|
		//      |....|         |..|                                 |....|
		//      | .. |                                              |....|
		// transform coordinate system (2): cut the borders, and reduce grid size to be multiple of 2
		// if `N/2` is odd this cuts off border coordinates x = N/2 - 1, y = N/2 - 1
		normalizedSize = (normalizedSize - 2) / 2 * 2;

		// define coordinate system: an isomorphic grid on a square of size [size, size]
		// transform coordinate system (3): pack an isomorphic grid on a rectangle of size [size, 1 + size / 2]
		// transform coordinate system (4): (x, y) -> y * size + x (two-dimensional Cartesian -> one-dimensional segment)
		// define temporary array to determine sites' coordinates
		uint16[] memory coords;
		// generate site coordinates in a transformed coordinate system (on a one-dimensional segment)
		// cut off four elements in the end of the segment to reserve space in the center for a landmark
		(seed, coords) = getCoords(seed, totalSites, normalizedSize * (1 + normalizedSize / 2) - 4);

		// allocate number of sites required
		sites = new Site[](totalSites);

		// define the variables used inside the loop outside the loop to help compiler optimizations
		// site type ID is de facto uint8, we're using uint16 for convenience with `nextRndUint16`
		uint16 typeId;
		// site coordinates (x, y)
		uint16 x;
		uint16 y;

		// determine the element and fuel sites one by one
		for(uint8 i = 0; i < totalSites; i++) {
			// determine next random number in the sequence, and random site type from it
			(seed, typeId) = nextRndUint16(seed, i < elementSites? 1: 4, 3);

			// determine x and y
			// reverse transform coordinate system (4): x = size % i, y = size / i
			// (back from one-dimensional segment to two-dimensional Cartesian)
			x = coords[i] % normalizedSize;
			y = coords[i] / normalizedSize;

			// reverse transform coordinate system (3): unpack isomorphic grid onto a square of size [size, size]
			// fix the "(0, 0) left-bottom corner" of the isomorphic grid
			if(2 * (1 + x + y) < normalizedSize) {
				x += normalizedSize / 2;
				y += 1 + normalizedSize / 2;
			}
			// fix the "(size, 0) right-bottom corner" of the isomorphic grid
			else if(2 * x > normalizedSize && 2 * x > 2 * y + normalizedSize) {
				x -= normalizedSize / 2;
				y += 1 + normalizedSize / 2;
			}

			// move the site from the center (four positions near the center) to a free spot
			if(x >= normalizedSize / 2 - 1 && x <= normalizedSize / 2
			&& y >= normalizedSize / 2 - 1 && y <= normalizedSize / 2) {
				// `x` is aligned over the free space in the end of the segment
				// x += normalizedSize / 2 + 2 * (normalizedSize / 2 - x) + 2 * (normalizedSize / 2 - y) - 4;
				x += 5 * normalizedSize / 2 - 2 * (x + y) - 4;
				// `y` is fixed over the free space in the end of the segment
				y = normalizedSize / 2;
			}

			// if `N/2` is odd recover previously cut off border coordinates x = N/2 - 1, y = N/2 - 1
			// if `N` is odd recover previously cut off border coordinates x = N - 1, y = N - 1
			uint16 offset = gridSize / siteSize % 2 + gridSize % siteSize;

			// based on the determined site type and coordinates, allocate the site
			sites[i] = Site({
				typeId: uint8(typeId),
				// reverse transform coordinate system (2): recover borders (x, y) => (x + 1, y + 1)
				// if `N/2` is odd recover previously cut off border coordinates x = N/2 - 1, y = N/2 - 1
				// reverse transform coordinate system (1): (x, y) => (n * x, n * y), where n is site size
				// if `N` is odd recover previously cut off border coordinates x = N - 1, y = N - 1
				x: (1 + x) * siteSize + offset,
				y: (1 + y) * siteSize + offset
			});
		}

		// return the result
		return sites;
	}

	/**
	 * @dev Based on the random seed and tier ID determines the landmark type of the plot.
	 *      Random seed is consumed for tiers 3 and 4 to randomly determine one of three
	 *      possible landmark types.
	 *      Tier 5 has its landmark type predefined (arena), lower tiers don't have a landmark.
	 *
	 * @dev Function works in a deterministic way and derives the same data
	 *      for the same inputs; the term "random" in comments means "pseudo-random"
	 *
	 * @param seed random seed to consume and derive the landmark type based on
	 * @param tierId tier ID of the land plot
	 * @return landmarkTypeId landmark type defined by its ID
	 */
	function getLandmark(uint256 seed, uint8 tierId) internal pure returns (uint8 landmarkTypeId) {
		// depending on the tier, land plot can have a landmark
		// tier 3 has an element landmark (1, 2, 3)
		if(tierId == 3) {
			// derive random element landmark
			return uint8(1 + seed % 3);
		}
		// tier 4 has a fuel landmark (4, 5, 6)
		if(tierId == 4) {
			// derive random fuel landmark
			return uint8(4 + seed % 3);
		}
		// tier 5 has an arena landmark
		if(tierId == 5) {
			// 7 - arena landmark
			return 7;
		}

		// lower tiers (0, 1, 2) don't have any landmark
		// tiers greater than 5 are not defined
		return 0;
	}

	/**
	 * @dev Derives an array of integers with no duplicates from the random seed;
	 *      each element in the array is within [0, size) bounds and represents
	 *      a two-dimensional Cartesian coordinate point (x, y) presented as one-dimensional
	 *
	 * @dev Function works in a deterministic way and derives the same data
	 *      for the same inputs; the term "random" in comments means "pseudo-random"
	 *
	 * @dev The input seed is considered to be already used to derive some random value
	 *      from it, therefore the function derives a new one by hashing the previous one
	 *      before generating the random value; the output seed is "used" - output random
	 *      value is derived from it
	 *
	 * @param seed random seed to consume and derive coordinates from
	 * @param length number of elements to generate
	 * @param size defines array element bounds [0, size)
	 * @return nextSeed next pseudo-random "used" seed
	 * @return coords the resulting array of length `n` with random non-repeating elements
	 *      in [0, size) range
	 */
	function getCoords(
		uint256 seed,
		uint8 length,
		uint16 size
	) internal pure returns (uint256 nextSeed, uint16[] memory coords) {
		// allocate temporary array to store (and determine) sites' coordinates
		coords = new uint16[](length);

		// generate site coordinates one by one
		for(uint8 i = 0; i < coords.length; i++) {
			// get next number and update the seed
			(seed, coords[i]) = nextRndUint16(seed, 0, size);
		}

		// sort the coordinates
		sort(coords);

		// find the if there are any duplicates, and while there are any
		for(int256 i = findDup(coords); i >= 0; i = findDup(coords)) {
			// regenerate the element at duplicate position found
			(seed, coords[uint256(i)]) = nextRndUint16(seed, 0, size);
			// sort the coordinates again
			// TODO: check if this doesn't degrade the performance significantly (note the pivot in quick sort)
			sort(coords);
		}

		// shuffle the array to compensate for the sorting made before
		seed = shuffle(seed, coords);

		// return the updated used seed, and generated coordinates
		return (seed, coords);
	}

	/**
	 * @dev Based on the random seed, generates next random seed, and a random value
	 *      not lower than given `offset` value and able to have `options` different
	 *      possible values
	 *
	 * @dev The input seed is considered to be already used to derive some random value
	 *      from it, therefore the function derives a new one by hashing the previous one
	 *      before generating the random value; the output seed is "used" - output random
	 *      value is derived from it
	 *
	 * @param seed random seed to consume and derive next random value from
	 * @param offset the minimum possible output
	 * @param options number of different possible values to output
	 * @return nextSeed next pseudo-random "used" seed
	 * @return rndVal random value in the [offset, offset + options) range
	 */
	function nextRndUint16(
		uint256 seed,
		uint16 offset,
		uint16 options
	) internal pure returns (
		uint256 nextSeed,
		uint16 rndVal
	) {
		// generate next random seed first
		nextSeed = uint256(keccak256(abi.encodePacked(seed)));

		// derive random value with the desired properties from
		// the newly generated seed
		rndVal = offset + uint16(nextSeed % options);

		// return the result as tuple
		return (nextSeed, rndVal);
	}

	/**
	 * @dev Plot location is a combination of (regionId, x, y), it's effectively
	 *      a 3-dimensional coordinate, unique for each plot
	 *
	 * @dev The function extracts plot location from the plot and represents it
	 *      in a packed form of 3 integers constituting the location: regionId | x | y
	 *
	 * @param plot `PlotView` view structure to extract location from
	 * @return Plot location (regionId, x, y) as a packed integer
	 */
/*
	function loc(PlotView memory plot) internal pure returns (uint40) {
		// tightly pack the location data and return
		return uint40(plot.regionId) << 32 | uint32(plot.y) << 16 | plot.x;
	}
*/

	/**
	 * @dev Plot location is a combination of (regionId, x, y), it's effectively
	 *      a 3-dimensional coordinate, unique for each plot
	 *
	 * @dev The function extracts plot location from the plot and represents it
	 *      in a packed form of 3 integers constituting the location: regionId | x | y
	 *
	 * @param plot `PlotStore` data store structure to extract location from
	 * @return Plot location (regionId, x, y) as a packed integer
	 */
	function loc(PlotStore memory plot) internal pure returns (uint40) {
		// tightly pack the location data and return
		return uint40(plot.regionId) << 32 | uint32(plot.y) << 16 | plot.x;
	}

	/**
	 * @dev Site location is a combination of (x, y), unique for each site within a plot
	 *
	 * @dev The function extracts site location from the site and represents it
	 *      in a packed form of 2 integers constituting the location: x | y
	 *
	 * @param site `Site` view structure to extract location from
	 * @return Site location (x, y) as a packed integer
	 */
/*
	function loc(Site memory site) internal pure returns (uint32) {
		// tightly pack the location data and return
		return uint32(site.y) << 16 | site.x;
	}
*/

	/**
	 * @dev Finds first pair of repeating elements in the array
	 *
	 * @dev Assumes the array is sorted ascending:
	 *      returns `-1` if array is strictly monotonically increasing,
	 *      index of the first duplicate found otherwise
	 *
	 * @param arr an array of elements to check
	 * @return index found duplicate index, or `-1` if there are no repeating elements
	 */
	function findDup(uint16[] memory arr) internal pure returns (int256 index) {
		// iterate over the array [1, n], leaving the space in the beginning for pair comparison
		for(uint256 i = 1; i < arr.length; i++) {
			// verify if there is a strict monotonically increase violation
			if(arr[i - 1] >= arr[i]) {
				// return its index if yes
				return int256(i - 1);
			}
		}

		// return `-1` if no violation was found - array is strictly monotonically increasing
		return -1;
	}

	/**
	 * @dev Shuffles an array if integers by making random permutations
	 *      in the amount equal to the array size
	 *
	 * @dev The input seed is considered to be already used to derive some random value
	 *      from it, therefore the function derives a new one by hashing the previous one
	 *      before generating the random value; the output seed is "used" - output random
	 *      value is derived from it
	 *
	 * @param seed random seed to consume and derive next random value from
	 * @param arr an array to shuffle
	 * @return nextSeed next pseudo-random "used" seed
	 */
	function shuffle(uint256 seed, uint16[] memory arr) internal pure returns(uint256 nextSeed) {
		// define index `j` to permute with loop index `i` outside the loop to help compiler optimizations
		uint16 j;

		// iterate over the array one single time
		for(uint16 i = 0; i < arr.length; i++) {
			// determine random index `j` to swap with the loop index `i`
			(seed, j) = nextRndUint16(seed, 0, uint16(arr.length));

			// do the swap
			(arr[i], arr[j]) = (arr[j], arr[i]);
		}

		// return the updated used seed
		return seed;
	}

	/**
	 * @dev Sorts an array of integers using quick sort algorithm
	 *
	 * @dev Quick sort recursive implementation
	 *      Source:   https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
	 *      See also: https://www.geeksforgeeks.org/quick-sort/
	 *
	 * @param arr an array to sort
	 */
	function sort(uint16[] memory arr) internal pure {
		quickSort(arr, 0, int256(arr.length) - 1);
	}

	/**
	 * @dev Quick sort recursive implementation
	 *      Source:     https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
	 *      Discussion: https://blog.cotten.io/thinking-in-solidity-6670c06390a9
	 *      See also:   https://www.geeksforgeeks.org/quick-sort/
	 */
	// TODO: review the implementation code
	function quickSort(uint16[] memory arr, int256 left, int256 right) private pure {
		int256 i = left;
		int256 j = right;
		if(i >= j) {
			return;
		}
		uint16 pivot = arr[uint256(left + (right - left) / 2)];
		while(i <= j) {
			while(arr[uint256(i)] < pivot) {
				i++;
			}
			while(pivot < arr[uint256(j)]) {
				j--;
			}
			if(i <= j) {
				(arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
				i++;
				j--;
			}
		}
		if(left < j) {
			quickSort(arr, left, j);
		}
		if(i < right) {
			quickSort(arr, i, right);
		}
	}
}