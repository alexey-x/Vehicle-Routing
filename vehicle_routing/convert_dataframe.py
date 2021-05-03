
def convert_dataframe_to_dict(dataframe, key_columns, value_column):
    return (
        dataframe.loc[:, key_columns + [value_column]]
        .set_index(key_columns)
        .to_dict()[value_column]
    )

def convert_dataframe_to_set(dataframe, key_columns, value_column):
    return set(
        list(convert_dataframe_to_dict(dataframe, key_columns, value_column).keys())
    )