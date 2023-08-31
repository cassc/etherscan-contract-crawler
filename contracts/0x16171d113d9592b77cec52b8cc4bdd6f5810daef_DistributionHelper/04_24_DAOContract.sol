// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../DAOStackInterfaces.sol";
import "../Interfaces.sol";

/**
@title Simple contract that keeps DAO contracts registery
*/

contract DAOContract {
	Controller public dao;

	address public avatar;

	INameService public nameService;

	function _onlyAvatar() internal view {
		require(
			address(dao.avatar()) == msg.sender,
			"only avatar can call this method"
		);
	}

	function setDAO(INameService _ns) internal {
		nameService = _ns;
		updateAvatar();
	}

	function updateAvatar() public {
		dao = Controller(nameService.getAddress("CONTROLLER"));
		avatar = dao.avatar();
	}

	function nativeToken() public view returns (IGoodDollar) {
		return IGoodDollar(nameService.getAddress("GOODDOLLAR"));
	}

	uint256[50] private gap;
}