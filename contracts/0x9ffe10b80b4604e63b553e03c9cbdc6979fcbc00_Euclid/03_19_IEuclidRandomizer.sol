// SPDX-License-Identifier: MIT
//
//  ********  **     **    ******   **        **  *******  
// /**/////  /**    /**   **////** /**       /** /**////** 
// /**       /**    /**  **    //  /**       /** /**    /**
// /*******  /**    /** /**        /**       /** /**    /**
// /**////   /**    /** /**        /**       /** /**    /**
// /**       /**    /** //**    ** /**       /** /**    ** 
// /******** //*******   //******  /******** /** /*******  
// ////////   ///////     //////   ////////  //  ///////   
//
// by collect-code 2022
// https://collect-code.com/
//
pragma solidity ^0.8.2;

interface IEuclidRandomizer {

	struct RandomizerState {
		uint32[4] state;
		uint32 value;
	}

	function makeSeed(address contractAddress, address senderAddress, uint blockNumber, uint256 tokenNumber) external view returns (uint128) ;
	function initialize(uint128 seed) external pure returns (RandomizerState memory);
	function initialize(bytes16 seed) external pure returns (RandomizerState memory);
	function getNextValue(RandomizerState memory self) external pure returns (RandomizerState memory);
	function getInt(RandomizerState memory self, uint32 maxExclusive) external pure returns (RandomizerState memory);
	function getIntRange(RandomizerState memory self, uint32 minInclusive, uint32 maxExclusive) external pure returns (RandomizerState memory);
}