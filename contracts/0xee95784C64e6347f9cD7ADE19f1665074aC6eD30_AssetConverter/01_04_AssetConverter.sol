pragma solidity >=0.8.0;


import "IERC20.sol";
import "Ownable.sol";


interface IConverter
{
	function swap(address source, address destination, uint256 value, address beneficiary) external returns (uint256);
}


contract AssetConverter is Ownable
{
	// sourve => destination converter
	mapping (address => mapping(address => IConverter)) public converters;

	constructor () Ownable()
	{

	}

	function updateConverter(address source, address destination, address newConverter) external onlyOwner
	{
		if (IERC20(source).allowance(address(this), newConverter) == 0) {
			IERC20(source).approve(newConverter, type(uint256).max);
		}
		converters[source][destination] = IConverter(newConverter);
	}

	function swap(address source, address destination, uint256 value) external returns (uint256)
	{
		IConverter converter = converters[source][destination];
		IERC20(source).transferFrom(msg.sender, address(converter), value);
		return converter.swap(source, destination, value, msg.sender);
	}
}