// SPDX-License-Identifier: MIT

/// @title Interface for Places
/// @author Places DAO

/*************************************
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 * ██░░░░░░░██████░░██████░░░░░░░░██ *
 * ░░░░░░░██████████████████░░░░░░░░ *
 * ░░░░░████████      ████████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░░░████  ██████  ████░░░░░░░░ *
 * ░░░░░░░░░████      ████░░░░░░░░░░ *
 * ░░░░░░░░░░░██████████░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░██████░░░░░░░░░░░░░░ *
 * ██░░░░░░░░░░░░░██░░░░░░░░░░░░░░██ *
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 *************************************/

pragma solidity ^0.8.6;

interface IPlaces {
    /**
     * @notice Location – Represents a geographic coordinate with altitude.
     *
     * Latitude and longitude values are in degrees under the WGS 84 reference
     * frame. Altitude values are in meters. Two location types are provided
     * int256 and string. The integer representation enables on chain computation
     * where as the string representation provides future computational compatability.
     *
     * Converting a location from a to integer uses GEO_RESOLUTION_INT denominator.
     * 37.73957402260721 encodes to 3773957402260721
     * -122.41902666230027 encodes to -12241902666230027
     *
     * hasAltitude – a boolean that indicates the validity of the altitude values
     * latitudeInt – integer representing the latitude in degrees encoded with
     * GEO_RESOLUTION_INT
     * longitudeInt – integer representing the longitude in degrees encoded with
     * GEO_RESOLUTION_INT
     * altitudeInt – integer representing the altitude in meters encoded with
     * GEO_RESOLUTION_INT
     * latitude – string representing the latitude coordinate in degrees under
     * the WGS 84 reference frame
     * longitude – string representing the longitude coordinate in degrees under
     * the WGS 84 reference frame
     * altitude – string representing the altitude measurement in meters
     */
    struct Location {
        int256 latitudeInt;
        int256 longitudeInt;
        int256 altitudeInt;
        bool hasAltitude;
        string latitude;
        string longitude;
        string altitude;
    }

    /**
     * @notice Place – Represents place information for a geographic location.
     *
     * name – string representing the place name
     * streetAddress – string indicating a precise address
     * sublocality – string representing the subdivision and first-order civil
     * entity below locality (neighborhood or common name)
     * locality – string representing the incorporated city or town political
     * entity
     * subadministrativeArea – string representing the subdivision of the
     * second-order civil entity (county name)
     * administrativeArea – string representing the second-order civil entity
     * below country (state or region name)
     * country – string representing the national political entity
     * postalCode – string representing the code used to address postal mail
     * within the country
     * countryCode – string representing the ISO 3166-1 country code,
     * https://en.wikipedia.org/wiki/ISO_3166-1
     * location – geographic location of the place, see Location type
     * attributes – string array of attributes describing the place
     */
    struct Place {
        string name;
        string streetAddress;
        string sublocality;
        string locality;
        string subadministrativeArea;
        string administrativeArea;
        string country;
        string postalCode;
        string countryCode;
        Location location;
        string[3] attributes;
    }
}