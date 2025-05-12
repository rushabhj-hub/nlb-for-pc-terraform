import boto3
import csv

AWS_REGION = "eu-west-1"  # Change as needed
PROFILE_NAME = "DeveloperAccess-251539659924"

# Start AWS session
session = boto3.Session(profile_name=PROFILE_NAME)
ec2_client = session.client("ec2", region_name=AWS_REGION)

def get_vpcs():
    """Fetch all VPCs in the region along with their names."""
    vpcs = ec2_client.describe_vpcs()["Vpcs"]
    vpc_list = []
    
    for vpc in vpcs:
        vpc_id = vpc["VpcId"]
        vpc_name = next((tag["Value"] for tag in vpc.get("Tags", []) if tag["Key"] == "Name"), "Unnamed VPC")
        vpc_list.append({"VpcId": vpc_id, "Name": vpc_name})
    
    return vpc_list

def get_subnets(vpc_id):
    """Fetch all subnets of a given VPC along with names."""
    subnets = ec2_client.describe_subnets(Filters=[{"Name": "vpc-id", "Values": [vpc_id]}])["Subnets"]
    subnet_list = []
    
    for subnet in subnets:
        subnet_id = subnet["SubnetId"]
        cidr_block = subnet["CidrBlock"]
        az = subnet["AvailabilityZone"]
        subnet_name = next((tag["Value"] for tag in subnet.get("Tags", []) if tag["Key"] == "Name"), "Unnamed Subnet")
        
        subnet_list.append({"SubnetId": subnet_id, "CIDR": cidr_block, "AZ": az, "Name": subnet_name, "VpcId": vpc_id})
    
    return subnet_list

def save_to_csv(vpcs, subnets, filename="vpcs_subnets.csv"):
    """Save VPCs and subnets data to a CSV file."""
    with open(filename, mode="w", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(["Type", "ID", "Name", "CIDR", "Availability Zone", "VpcId"])  # Header

        for vpc in vpcs:
            writer.writerow(["VPC", vpc["VpcId"], vpc["Name"], "-", "-", "-"])
        
        for subnet in subnets:
            writer.writerow(["Subnet", subnet["SubnetId"], subnet["Name"], subnet["CIDR"], subnet["AZ"], subnet["VpcId"]])

    print(f"Data saved to {filename}")

# Main function
if __name__ == "__main__":
    # Fetch VPCs
    vpcs = get_vpcs()
    
    #print("\nAvailable VPCs:")
    #for vpc in vpcs:
        #print(f"- VPC ID: {vpc['VpcId']}, Name: {vpc['Name']}")

    # Fetch subnets for all VPCs
    all_subnets = []
    for vpc in vpcs:
        subnets = get_subnets(vpc["VpcId"])
        all_subnets.extend(subnets)

    #print("\nAvailable Subnets:")
    #for subnet in all_subnets:
        #print(f"- Subnet ID: {subnet['SubnetId']}, CIDR: {subnet['CIDR']}, AZ: {subnet['AZ']}, Name: {subnet['Name']}, VPC ID: {subnet['VpcId']}")

    # Save to CSV
    save_to_csv(vpcs, all_subnets)
